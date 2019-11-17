#!/bin/bash 

IMAGE_FILE=$1

if [ -a ${IMAGE_FILE} ]
then
	echo "IMAGE_FILE [${IMAGE_FILE}] already exist, remove it first."
	exit 2
fi

dd if=/dev/zero of=${IMAGE_FILE} bs=1M count=100

DEVICE=$(losetup -f --show ${IMAGE_FILE})

parted ${DEVICE} <<EOF
mktable msdos
mkpart primary fat16 1M 20M
mkpart primary ext4 20M 100%
toggle 1 boot
print
quit

EOF

losetup -d ${DEVICE}

declare -a DEVPARTS
count=0
for dev in $(kpartx -av ${IMAGE_FILE} | awk '{print $3}')
do
	DEVPARTS[count]=${dev}
	echo device is ${DEVPARTS[count]}
	mkdir -p /tmp/${DEVPARTS[count]}
	count=$((count + 1))
done

mkfs.vfat -n "BOOT" /dev/mapper/${DEVPARTS[0]}
mkfs.ext4 -L "ROOT" /dev/mapper/${DEVPARTS[1]}

mount -t vfat /dev/mapper/${DEVPARTS[0]} /tmp/${DEVPARTS[0]}
mount -t ext4 /dev/mapper/${DEVPARTS[1]} /tmp/${DEVPARTS[1]}

IMAGES_DIR=$2
pushd ${IMAGES_DIR}

cp MLO /tmp/${DEVPARTS[0]}
cp u-boot.img /tmp/${DEVPARTS[0]}cd ${BUILDDIR}/tmp/deploy/images
cp *.dtb /tmp/${DEVPARTS[0]}
cp zImage /tmp/${DEVPARTS[0]}

cat > /tmp/${DEVPARTS[0]}/uEnv.txt <<'EOF'
bootpart=0:1
devtype=mmc
bootdir=
bootfile=zImage
bootpartition=mmcblk0p2
set_mmc1=if test $board_name = A33515BB; then setenv bootpartition mmcblk1p2; fi
set_bootargs=setenv bootargs console=ttyO0,115200n8 root=/dev/${bootpartition} rw rootfstype=ext4 rootwait
uenvcmd=run set_mmc1; run set_bootargs;run loadimage;run loadfdt;printenv bootargs;bootz ${loadaddr} - ${fdtaddr}
EOF

tar xvfJ core-image-minimal-beaglebone.tar.xz -C /tmp/${DEVPARTS[1]}
tar xvfz modules-beaglebone.tgz -C /tmp/${DEVPARTS[1]}

popd

sync

for dev in ${DEVPARTS[@]}
do
	umount /tmp/${dev}
	rmdir /tmp/${dev}
done

kpartx -d ${IMAGE_FILE}

