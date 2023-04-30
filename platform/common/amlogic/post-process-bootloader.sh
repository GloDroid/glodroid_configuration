#!/bin/bash

set -e

# 1: FIP dir
# 2: Generation (g12a or g12b)
# 3: Destination Binary
# 4: U-Boot binary
# 5: Type (sd or emmc)

TYPE=$5
FIPDIR=$PWD/$1

TMPDIR=$(mktemp -d)

post_process_g12() {
    ${FIPDIR}/blx_fix.sh ${FIPDIR}/bl30.bin \
              zero_tmp \
              bl30_zero.bin \
              ${FIPDIR}/bl301.bin \
              bl301_zero.bin \
              bl30_new.bin bl30

    ${FIPDIR}/blx_fix.sh ${FIPDIR}/bl2.bin \
              zero_tmp \
              bl2_zero.bin \
              ${FIPDIR}/acs.bin \
              bl21_zero.bin \
              bl2_new.bin bl2

    ${FIPDIR}/aml_encrypt_$1 --bl30sig \
                --input bl30_new.bin \
                --output bl30_new.bin.g12.enc \
                --level v3
    ${FIPDIR}/aml_encrypt_$1 --bl3sig \
                --input bl30_new.bin.g12.enc \
                --output bl30_new.bin.enc \
                --level v3 --type bl30
    ${FIPDIR}/aml_encrypt_$1 --bl3sig \
                --input ${FIPDIR}/bl31.img \
                --output bl31.img.enc \
                --level v3 --type bl31
    ${FIPDIR}/aml_encrypt_$1 --bl3sig \
                --input bl33.bin \
                --compress lz4 \
                --output bl33.bin.enc \
                --level v3 --type bl33
    ${FIPDIR}/aml_encrypt_$1 --bl2sig \
                --input bl2_new.bin \
                --output bl2.n.bin.sig
    if [ -e ${FIPDIR}/lpddr3_1d.fw ]
    then
        ${FIPDIR}/aml_encrypt_$1 --bootmk --output u-boot.bin \
            --bl2 bl2.n.bin.sig \
            --bl30 bl30_new.bin.enc \
    ￼		--bl31 bl31.img.enc \
            --bl33 bl33.bin.enc \
            --ddrfw1 ${FIPDIR}/ddr4_1d.fw \
            --ddrfw2 ${FIPDIR}/ddr4_2d.fw \
            --ddrfw3 ${FIPDIR}/ddr3_1d.fw \
            --ddrfw4 ${FIPDIR}/piei.fw \
            --ddrfw5 ${FIPDIR}/lpddr4_1d.fw \
            --ddrfw6 ${FIPDIR}/lpddr4_2d.fw \
            --ddrfw7 ${FIPDIR}/diag_lpddr4.fw \
            --ddrfw8 ${FIPDIR}/aml_ddr.fw \
            --ddrfw9 ${FIPDIR}/lpddr3_1d.fw \
            --level v3
    else
        ${FIPDIR}/aml_encrypt_$1 --bootmk  --output u-boot.bin \
            --bl2 bl2.n.bin.sig \
            --bl30 bl30_new.bin.enc \
            --bl31 bl31.img.enc \
            --bl33 bl33.bin.enc \
            --ddrfw1 ${FIPDIR}/ddr4_1d.fw \
            --ddrfw2 ${FIPDIR}/ddr4_2d.fw \
            --ddrfw3 ${FIPDIR}/ddr3_1d.fw \
            --ddrfw4 ${FIPDIR}/piei.fw \
            --ddrfw5 ${FIPDIR}/lpddr4_1d.fw \
            --ddrfw6 ${FIPDIR}/lpddr4_2d.fw \
            --ddrfw7 ${FIPDIR}/diag_lpddr4.fw \
            --ddrfw8 ${FIPDIR}/aml_ddr.fw \
            --level v3
    fi
}

post_process_gxl() {
    ${FIPDIR}/blx_fix.sh ${FIPDIR}/bl30.bin \
            zero_tmp \
            bl30_zero.bin \
            ${FIPDIR}/bl301.bin \
            bl301_zero.bin \
            bl30_new.bin bl30

    python ${FIPDIR}/acs_tool.py ${FIPDIR}/bl2.bin \
            bl2_acs.bin \
            ${FIPDIR}/acs.bin 0

    ${FIPDIR}/blx_fix.sh bl2_acs.bin \
            zero_tmp \
            bl2_zero.bin \
            ${FIPDIR}/bl21.bin \
            bl21_zero.bin \
            bl2_new.bin bl2

    ${FIPDIR}/aml_encrypt_gxl --bl3enc \
            --input bl30_new.bin
    ${FIPDIR}/aml_encrypt_gxl --bl3enc \
            --input ${FIPDIR}/bl31.img
    ${FIPDIR}/aml_encrypt_gxl --bl3enc \
            --input bl33.bin
    ${FIPDIR}/aml_encrypt_gxl --bl2sig \
            --input bl2_new.bin \
            --output bl2.n.bin.sig
    ${FIPDIR}/aml_encrypt_gxl --bootmk --output u-boot.bin \
            --bl2 bl2.n.bin.sig \
            --bl30 bl30_new.bin.enc \
            --bl31 bl31.img.enc \
            --bl33 bl33.bin.enc
}

cp $4 $TMPDIR/bl33.bin

pushd $TMPDIR

case $2 in
g12a|g12b)
    post_process_g12 $2
    ;;
sm1)
    post_process_g12 g12a
    ;;
gxl|gxm)
    post_process_gxl g12a
    ;;
*)
    echo "Unsupported family $2"
    exit 1
    ;;
esac

popd

if [ "$TYPE" = "SD" ] ; then
	cp $TMPDIR/u-boot.bin.sd.bin $3
else
	cp $TMPDIR/u-boot.bin $3
fi

rm -fr $TMPDIR

exit 0
