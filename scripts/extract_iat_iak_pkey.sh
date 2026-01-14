#!/bin/bash

OPENOCD_PATH="C:/Infineon/Tools/ModusToolboxProgtools-vx.y/openocd"

echo "Extracting Initial Attestation token from SRAM1 shared memory..."
echo "openocd logs stored in openocd_logs.txt"
${OPENOCD_PATH}/bin/openocd.exe -s ../scripts -f interface/kitprog3.cfg -f target/infineon/pse84xgxs2.cfg -c "init; reset init; dump_image ./Attestation_token.cbor 0x240fe000 1024; shutdown" &>openocd_logs.txt
echo "Attestation Token extracted. Token stored in Attestation_token.cbor"

echo "Extracting Alias Certificate from device..."
echo "Edgeprotectools logs stored in edgeprotecttools_cert_logs.txt"
edgeprotecttools -t pse8xs2 init

edgeprotecttools set-ocd -n openocd -p ${OPENOCD_PATH} -c infineon/pse84xgxs2.cfg

edgeprotecttools -t pse84 integrity-exam --alias-cert alias_cert.cbor &>edgeprotecttools_cert_logs.txt
echo "Alias Certificate extracted. Certificate stored in alias_cert.cbor"

echo "Extracting IAK public key from alias certificate"
IAK_PUB_KEY="$(edgeprotecttools cbor2json -i alias_cert.cbor | grep -i "PUBLIC_KEY_0" | cut -d"'" -f2)"
STR="/\"pub\": /c \  \"pub\": \"${IAK_PUB_KEY}\""
sed -i "${STR}" keys/ec_key_tmpl.json
edgeprotecttools create-key --key-type ECDSA-P256 --template keys/ec_key_tmpl.json --format PEM -o IAK_PUB_KEY.pem
echo "IAK public key extracted. Key stored in IAK_PUB_KEY.pem"