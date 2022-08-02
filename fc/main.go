package main

import (
	"context"
	"errors"
	"fmt"
	"os"
	"path/filepath"

	"github.com/aliyun/aliyun-oss-go-sdk/oss"
	"github.com/aliyun/fc-runtime-go-sdk/events"
	"github.com/aliyun/fc-runtime-go-sdk/fc"
	"github.com/aliyun/fc-runtime-go-sdk/fccontext"
)

const (
	mntPoint   = "/mnt/grocery"
	bucketName = "solus-grocery-store-oss"
	indexFile  = "eopkg-index.xml"
)

var (
	indexFiles = [4]string{
		"eopkg-index.xml.xz",
		"eopkg-index.xml.xz.sha1sum",
		"eopkg-index.xml",
		"eopkg-index.xml.sha1sum",
	}
)

func HandleRequest(ctx context.Context, event events.OssEvent) error {
	fcctx, _ := fccontext.FromContext(ctx)
	credentials := fcctx.Credentials
	logger := fcctx.GetLogger()

	if len(event.Events) > 1 {
		logger.Error("More than two events received, I can't handle them:", event.Events)
		return errors.New(fmt.Sprintf("Expecting 1 event, received %d", len(event.Events)))
	}

	// Connect to OSS.
	logger.Info("Connecting to OSS using endpoint: " + "oss-" + fcctx.Region + "-internal.aliyuncs.com")
	client, err := oss.New("oss-"+fcctx.Region+"-internal.aliyuncs.com", credentials.AccessKeyId, credentials.AccessKeySecret, oss.SecurityToken(credentials.SecurityToken))
	if err != nil {
		logger.Error("Failed to connect to OSS:", err)
		return err
	} else {
		logger.Info("Successfully connected to OSS!")
	}

	// Connect to bucket.
	bucket, err := client.Bucket(bucketName)
	if err != nil {
		logger.Error("Failed to connect to OSS bucket:", err)
		return err
	}

	// Get the (relative) path of the package.
	obj := event.Events[0].Oss.Object
	pkgPath := obj.Key
	nasPkgPath := filepath.Join(mntPoint, *pkgPath)

	// Create the corresponding location in NAS if it doesn't exist.
	err = os.Mkdir(filepath.Dir(nasPkgPath), 00755)
	if err != nil {
		logger.Error("Failed to create path for package in NAS:", err)
		return err
	}

	// Download object from OSS to NAS.
	err = bucket.GetObjectToFile(*pkgPath, nasPkgPath)
	if err != nil {
		logger.Error("Failed to download package from OSS:", err)
		return err
	}

	err = indexDir(mntPoint, ctx)
	if err != nil {
		return err
	}

	for _, file := range indexFiles {
		err = bucket.PutObjectFromFile(file, filepath.Join(mntPoint, file))
		if err != nil {
			return err
		}
	}

	return nil
}

func main() {
	fc.Start(HandleRequest)
}
