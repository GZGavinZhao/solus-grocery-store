package main

import (
	"context"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/aliyun/aliyun-oss-go-sdk/oss"
	"github.com/aliyun/fc-runtime-go-sdk/events"
	"github.com/aliyun/fc-runtime-go-sdk/fccontext"
)

func FCEnvDebug(ctx context.Context, event events.OssEvent) error {
	fcctx, _ := fccontext.FromContext(ctx)
	credentials := fcctx.Credentials
	logger := fcctx.GetLogger()

	logger.Debug("Uid:", os.Getuid())
	logger.Debug("Gid:", os.Getgid())
	logger.Debug("User:", fcctx.AccountId)

	if _, err := os.Stat(mntPoint); err != nil {
		if os.IsNotExist(err) {
			logger.Error("NAS doesn't seem to be mounted!")
		} else {
			logger.Error(err)
		}
		return err
	}

	logger.Info("Try if we can write file to NAS...")
	if err := os.WriteFile(filepath.Join(mntPoint, "test.txt"), []byte("Hello NAS from FC!"), 0666); err != nil {
		logger.Error(err)
	} else {
		logger.Info("Successfully wrote file to NAS!")
	}

	logger.Info("Try if we can read file in NAS...")
	if _, err := os.ReadFile(filepath.Join(mntPoint, "test.txt")); err != nil {
		logger.Error(err)
	} else {
		logger.Info("Successfully read file in NAS!")
	}

	logger.Info("See if we can delete file in NAS...")
	if err := os.Remove(filepath.Join(mntPoint, "test.txt")); err != nil {
		logger.Error(err)
	} else {
		logger.Info("Successfully deleted file in NAS!")
	}

	logger.Info("Connecting to OSS using endpoint: " + "oss-" + fcctx.Region + "-internal.aliyuncs.com")
	client, err := oss.New("oss-"+fcctx.Region+"-internal.aliyuncs.com", credentials.AccessKeyId, credentials.AccessKeySecret, oss.SecurityToken(credentials.SecurityToken))
	if err != nil {
		logger.Error(err)
	} else {
		logger.Info("Successfully connected to OSS!")
	}

	bucket, err := client.Bucket(bucketName)
	if err != nil {
		logger.Error(err)
	}
	if err := bucket.PutObject("fctest.txt", strings.NewReader("Hello OSS from FC!")); err != nil {
		logger.Error(err)
	} else {
		logger.Info("Successfully wrote file to OSS!")
	}

	logger.Info("Listing top-level files in NAS...")
	exec.Command("ls", mntPoint)

	return nil
}
