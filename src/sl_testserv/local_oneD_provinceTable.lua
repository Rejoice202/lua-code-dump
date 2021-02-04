--ANSI编码的全局TABLE
--使用两个一维数组
--查省会城市名：CAPCITY[province]
--生成该省全部元素的完整矩阵：PROVINCEARRAY[province]
--使用局部变量

local AnHuiAY = {}
local BeiJingAY = {}
local FuJianAY = {}
local GanSuAY = {}
local GuangDongAY = {}
local GuangXiAY = {}
local GuiZhouAY = {}
local HaiNanAY = {}
local HeBeiAY = {}
local HeNanAY = {}
local HeiLongJiangAY = {}
local HuBeiAY = {}
local HuNanAY = {}
local JiLinAY = {}
local JiangSuAY = {}
local JiangXiAY = {}
local LiaoNingAY = {}
local NeiMengGuAY = {}
local NingXiaAY = {}
local QingHaiAY = {}
local ShanDongAY = {}
local ShanXiAY = {}
local SHANXIAY = {}
local ShangHaiAY = {}
local SiChuanAY = {}
local TianJinAY = {}
local TibetAY = {}
local XinJiangAY = {}
local YunNanAY = {}
local ZheJiangAY = {}
local ChongQingAY = {}



CAPCITY = {
["安徽"] = "合肥",
["北京"] = "北京",
["福建"] = "福州",
["甘肃"] = "杭州",
["广东"] = "广州",
["广西"] = "南宁",
["贵州"] = "贵阳",
["海南"] = "海口",
["河北"] = "石家庄",
["河南"] = "郑州",
["黑龙江"] = "哈尔滨",
["湖北"] = "武汉",
["湖南"] = "长沙",
["吉林"] = "长春",
["江苏"] = "南京",
["江西"] = "南昌",
["辽宁"] = "沈阳",
["内蒙古"] = "呼和浩特",
["宁夏"] = "银川",
["青海"] = "西宁",
["山东"] = "济南",
["山西"] = "太原",
["陕西"] = "西安",
["上海"] = "上海",
["四川"] = "成都",
["天津"] = "天津",
["西藏"] = "拉萨",
["新疆"] = "乌鲁木齐",
["云南"] = "昆明",
["浙江"] = "杭州",
["重庆"] = "重庆",

}

-- ZheJiangAY = {}
-- GuangDongAY = {}
PROVINCEARRAY = {
["安徽"] = AnHuiAY,
["北京"] = BeiJingAY,
["福建"] = FuJianAY,
["甘肃"] = GanSuAY,
["广东"] = GuangDongAY,
["广西"] = GuangXiAY,
["贵州"] = GuiZhouAY,
["海南"] = HaiNanAY,
["河北"] = HeBeiAY,
["河南"] = HeNanAY,
["黑龙江"] = HeiLongJiangAY,
["湖北"] = HuBeiAY,
["湖南"] = HuNanAY,
["吉林"] = JiLinAY,
["江苏"] = JiangSuAY,
["江西"] = JiangXiAY,
["辽宁"] = LiaoNingAY,
["内蒙古"] = NeiMengGuAY,
["宁夏"] = NingXiaAY,
["青海"] = QingHaiAY,
["山东"] = ShanDongAY,
["山西"] = ShanXiAY,
["陕西"] = SHANXIAY,
["上海"] = ShangHaiAY,
["四川"] = SiChuanAY,
["天津"] = TianJinAY,
["西藏"] = TibetAY,
["新疆"] = XinJiangAY,
["云南"] = YunNanAY,
["浙江"] = ZheJiangAY,
["重庆"] = ChongQingAY,
}




eop_province = {
["安徽"] = 29,
["北京"] = 0,
["福建"] = 17,
["甘肃"] = 27,
["广东"] = 18,
["广西"] = 19,
["贵州"] = 20,
["海南"] = 30,
["河北"] = 8,
["河南"] = 9,
["黑龙江"] = 6,
["湖北"] = 13,
["湖南"] = 12,
["吉林"] = 5,
["江苏"] = 15,
["江西"] = 14,
["辽宁"] = 4,
["内蒙古"] = 7,
["宁夏"] = 25,
["青海"] = 24,
["山东"] = 10,
["山西"] = 11,
["陕西"] = 26,
["上海"] = 1,
["四川"] = 22,
["天津"] = 2,
["西藏"] = 23,
["新疆"] = 28,
["云南"] = 21,
["浙江"] = 16,
["重庆"] = 3,
}



-- select phonenum, locationid from numtabmob where phonenum=(select max(phonenum) from numtabmob where phonenum= '1881'or phonenum='18811' or phonenum='188110' or phonenum='1881101'or phonenum='18811016');