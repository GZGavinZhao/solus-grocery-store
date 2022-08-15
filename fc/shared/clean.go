package shared

import (
	"os"
	"path/filepath"

	"github.com/aliyun/aliyun-oss-go-sdk/oss"
)

func Clean(bucket *oss.Bucket, nasPath string) error {
	nasLen := len(nasPath)
	if nasPath[nasLen-1] != '/' {
		nasLen++
	}

	err := filepath.WalkDir(nasPath, func(path string, d os.DirEntry, err error) error {
		if err != nil {
			return err
		}

		if !d.IsDir() && isEopkg(path) {
			key := path[nasLen:]

			exists, err := bucket.IsObjectExist(key)
			if err != nil {
				return err
			}

			if !exists {
				err := DeleteFile(path)
				if err != nil {
					return err
				}
			}
		}

		return nil
	})

	return err
}
