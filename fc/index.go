package main

import (
	"context"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/GZGavinZhao/libeopkg/archive"
	"github.com/GZGavinZhao/libeopkg/index"
	"github.com/GZGavinZhao/libeopkg/shared"
	"github.com/aliyun/fc-runtime-go-sdk/fccontext"
)

var (
	distribution = index.Distribution{
		SourceName: "Solus",
		Version:    1,
		Type:       "main",
		BinaryName: "Solus",
	}
)

func indexDir(dir string, ctx context.Context) error {
	fcctx, _ := fccontext.FromContext(ctx)
	// credentials := fcctx.Credentials
	logger := fcctx.GetLogger()

	// We'll support loading from an existing index later...
	//
	// logger.Info("Loading existing index file if exists...")
	// var idx index.Index
	// indexFilePath := filepath.Join(dir, indexFile)
	// if _, err := os.Stat(indexFilePath); errors.Is(err, os.ErrNotExist) {
	// 	idx = index.Index{}
	// } else if err == nil {
	// 	idxPtr, err := index.Load(indexFilePath)
	// 	if err != nil {
	// 		// logger.Error("Unable to load", indexFilePath, ":", err)
	// 		return err
	// 	}

	// 	idx = *idxPtr
	// } else {
	// 	// logger.Error("Unable to open", indexFilePath, ":", err)
	// 	return err
	// }

	var idx = index.Index{Distribution: distribution}
	var pkgs = make(map[string]*archive.Package)

	logger.Info("Walking the given directory to find indexable packages...")
	// First walk, get an idea of what packages we have.
	err := filepath.WalkDir(dir,
		func(path string, entry os.DirEntry, err error) error {
			if err != nil {
				return err
			}
			if !entry.IsDir() && isEopkg(path) && !isDelta(path) {
				eopkg, err := archive.Open(path)
				if err != nil {
					return err
				}
				defer eopkg.Close()

				err = eopkg.ReadMetadata()
				if err != nil {
					return err
				}

				pkg := *eopkg.Meta.Package
				name := pkg.Name
				release := pkg.GetRelease()

				err = verifyPackageLocation(path, pkg, dir)
				if err != nil {
					return err
				}
				pkg.PackageURI = filepath.Join(pkg.GetPathComponent(), filepath.Base(path))

				if _, exists := pkgs[name]; !exists {
					// Not met before.
					pkgs[name] = &pkg
				} else if pkgs[name].History[0].Release < release {
					// Newer release
					pkgs[name] = &pkg
				} else if pkgs[name].History[0].Release == release {
					// Same release, should never happen
					return errors.New(fmt.Sprintf("Package %s has two packages with the same release version %d, path ", name, release))
				}
			}
			return nil
		})
	if err != nil {
		return err
	}

	logger.Info("Associating delta packages to their parent packages...")
	err = filepath.WalkDir("build",
		func(path string, entry os.DirEntry, err error) error {
			if !entry.IsDir() && isDelta(path) {
				// We have to use the file name to get its previous versions...
				// logger.Println(path)

				eopkg, err := archive.Open(path)
				if err != nil {
					return err
				}
				defer eopkg.Close()

				err = eopkg.ReadMetadata()
				if err != nil {
					return err
				}

				pkg := *eopkg.Meta.Package
				name := pkg.Name
				parent := pkgs[name]

				splitted := strings.Split(filepath.Base(path)[len(name):], "-")
				// Why is there a space at the front???
				toVer, err := strconv.Atoi(splitted[2])
				if err != nil {
					return err
				}

				if toVer == parent.History[0].Release {
					fromVer, err := strconv.Atoi(splitted[1])
					if err != nil {
						return nil
					}

					hash, size, err := sha1AndSize(path, ctx)
					if err != nil {
						return err
					}

					err = verifyPackageLocation(path, pkg, dir)
					if err != nil {
						return err
					}

					parent.DeltaPackages = append(parent.DeltaPackages, shared.Delta{
						ReleaseFrom: fromVer,
						PackageURI:  filepath.Join(pkg.GetPathComponent(), filepath.Base(path)),
						PackageHash: hash,
						PackageSize: size,
					})
				}
			}
			return nil
		})

	logger.Info("Calculating shas and adding fully cooked packages to the index...")
	for _, pkg := range pkgs {
		sha, size, err := sha1AndSize(filepath.Join(dir, pkg.PackageURI), ctx)
		if err != nil {
			return err
		}

		pkg.PackageHash = sha
		pkg.PackageSize = size
		idx.Packages = append(idx.Packages, *pkg)
	}

	logger.Info("Saving index...")
	err = idx.Save(dir)
	if err != nil {
		return err
	}

	return nil
}
