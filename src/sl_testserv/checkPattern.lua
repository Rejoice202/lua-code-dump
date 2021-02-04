--功  能：判断给定字符串的组合类型
--参  数：string
--返回值：false, 正确参数的类型标识 pattern
--备  注：7种类型:
--1 英文、数字+英文符、数字、英文+数字+英文符、中文、数字+英文、英文、中文+英文+数字”
function _CheckParamsPattern(strings)
    local  value = gb_utf8(strings)
    --[=[ UTF8的编码规则：  
        1. 字符的第一个字节范围：0x00—0x7F(0-127),或者 0xC2—0xF4(194-244); UTF8兼容 ascii，所以 0~127 就和 ascii 完全一致  
        2. 0xC0, 0xC1,0xF5—0xFF(192, 193 和 245-255)不会出现在UTF8编码中   
        3. 0x80—0xBF(128-191)只会出现在第二个及随后的编码中(针对多字节编码，如汉字)
        4.通常，汉字范围从0x4E00到0x9FA5(Unicode编码),对于UTF-8还要做转换。
            其中，0x4E00 用二进制表示为  100111000000000
            换成UTF-8码就是 11100100 10111000 10000000，即 228, 184, 128
            同理，0x9FA5为  11101001 10111110 10100101，即 233, 190, 165
            可以看出，中文UTF-8编码用3个字节表示。
        5.中文判断方法:
            比较第一个字节是228-233，而且接下来两个字节都是 128-191，即可以简单认定为中文   
        ]=]

    ---[==[
    local Eng,Num,Sym,CH = 1,2,4,8 --元类型标识
    local Punctuation, Number, English, Chineness = 0, 0, 0, 0  --字符串类型标识
    local byteCount = 1; j = 1 
    local Head, Head2, Head3, Tail, Tail2, Tail3 = 228, 184, 128, 233, 191, 191 --中文范围：228 184 128 -- 233 191 191
    --logf("value: %s; #value is %s", value, #value)
    while (j <= #value) do --从第一个字符判断其类型
        local utf8byte = string.byte(value, j)
        --logf("j=[%s], utf8byte is: %s", j, utf8byte)
        if not utf8byte then break
        elseif utf8byte < 192 then  -- < 127, 英文字符及数字判断 
		--英文字特殊符[91=[ 92=\ 93=] 94=^ 95=_ 96=`]:
            if (31<utf8byte and utf8byte<48) or (57<utf8byte and utf8byte<65) or (90<utf8byte and utf8byte<97) or (122<utf8byte and utf8byte<127) then --字符:类型标识为4
                Punctuation = Sym
            elseif 47<utf8byte and utf8byte<58 then --数字: 2
                Number = Num 
            elseif (64<utf8byte and utf8byte<91) or (96<utf8byte and utf8byte<123) then --大小写英文字符: 1 (65-90小写english, 97-122大写english)
                English = Eng
            end 
            byteCount = 1
        elseif (utf8byte>=Head) and (utf8byte<=Tail) then --[228, 233]第一个字节编码在此范围内，则比较后续两字节
            local second = string.byte(value, j + 1)
            local third = string.byte(value, j + 2) 
            if (not second) or (not third) then 
                logf("invalid paraments") -- TODO TEST
                return false 
            elseif utf8byte == Head then 
                if (second < Head2) or (second == Head2 and third < Head3) then 
                    logf("invalid paraments") -- TODO TEST
                    return false 
                end 
            elseif utf8byte == Tail then 
                if (second > Tail2) or (second == Tail2 and third > Tail3) then 
                    logf("invalid paraments") -- TODO TEST
                    return false
                end
            end 
            --logf("Chineness char ...") -- TODO TEST        
            Chineness = CH
            byteCount = 3
        else --非中文, 错误参数 :[if utf8byte > 233 then] 
            logf("invalid paraments") -- TODO TEST
            return false 
        end
        j = j + byteCount 
    end--]==]
	logf("English = '%s' Number = '%s' Punctuation = '%s' Chineness = '%s'",English , Number , Punctuation , Chineness )
    local Pattern = English + Number + Punctuation + Chineness 
    --logf("English[%s] + Number[%s] + Punctuation[%s] + Chineness[%s] = [%s]", English, Number, Punctuation, Chineness, Pattern) -- TODO TEST 
    return Pattern
end

function checkPattern_v1(argt)
	local r = _CheckParamsPattern(argt.str)
	logf(r)
end


lib_cmdtable["checkPattern_v1"] = checkPattern_v1	--curl -v -k http://127.0.0.1:6081/testserv/v1/checkPattern -d '{"str":"3d"}'

