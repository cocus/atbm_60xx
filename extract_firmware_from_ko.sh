#!/bin/bash

FIL="atbm603x_wifi_sdio.ko"

read_section_offset() {
    local _f="$1"
    local _sect="$2"

    info="$(readelf --sections $_f | grep "\[$_sect\]" | tr -s ' ' )"
    offset="$(echo $info | cut -d' ' -f5)"

    echo $offset
}

extract_sym() {
    local _f="$1"
    local _sym="$2"
    local _outname="$3"

    info="$(readelf -Ws $_f | grep $_sym | tr -s ' ')"

    sect_num="$(echo $info | rev | cut -d' ' -f2 | rev)"
    offset="$(echo $info | cut -d' ' -f2)"
    sz="$(echo $info | cut -d' ' -f3)"
    if [[ $sz == "0x"* ]]; then
        sz=$(printf "%d" $((16#${sz#0x})))
    fi

    echo "sect_num: $sect_num, offset from section: $offset, size: $sz"

    sect_offset=$(read_section_offset $_f $sect_num)
    echo " -> section offset is $sect_offset"
    file_offset=$(printf "%d" $((16#$sect_offset + 16#$offset)))
    echo " -> file offset is $file_offset"

    tmpfile=$(mktemp)

    dd if=$_f of=$tmpfile bs=$file_offset skip=1
    dd if=$tmpfile of=$_outname bs=$sz count=1
    rm $tmpfile
}

get_c_array_from_bin() {
    local _f="$1"
    local _name="$2"

    echo "$(xxd -i $_f | sed "s/${_name}_bin/$_name/" )"
}


re_gen_firmware_sdio_h() {
    local _f_hdr="$1"
    local _n_hdr="$2"

    local _f_code="$3"
    local _s_code="$4"

    local _f_data="$5"
    local _s_data="$6"

    local _f_out="$7"


    # I'm using their typo as well!
    echo "#ifndef _FIMEWARE_H_" > $_f_out
    echo "#define _FIMEWARE_H_" >> $_f_out
    echo "" >> $_f_out

    echo "$(get_c_array_from_bin $_f_hdr "$_s_hdr")" >> $_f_out
    echo "" >> $_f_out
    echo "$(get_c_array_from_bin $_f_code "$_s_code")" >> $_f_out
    echo "" >> $_f_out
    echo "$(get_c_array_from_bin $_f_data "$_s_data")" >> $_f_out
    echo "" >> $_f_out

    echo "#endif" >> $_f_out
}


extract_sym $FIL "firmware_headr" "firmware_headr.bin"
extract_sym $FIL "fw_code" "fw_code.bin"
extract_sym $FIL "fw_data" "fw_data.bin"


re_gen_firmware_sdio_h \
    "firmware_headr.bin" "firmware_headr" \
    "fw_code.bin" "fw_code" \
    "fw_data.bin" "fw_data" \
    "hal_apollo/firmware_sdio.h"
