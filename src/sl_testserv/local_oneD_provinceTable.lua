--ANSI�����ȫ��TABLE
--ʹ������һά����
--��ʡ���������CAPCITY[province]
--���ɸ�ʡȫ��Ԫ�ص���������PROVINCEARRAY[province]
--ʹ�þֲ�����

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
["����"] = "�Ϸ�",
["����"] = "����",
["����"] = "����",
["����"] = "����",
["�㶫"] = "����",
["����"] = "����",
["����"] = "����",
["����"] = "����",
["�ӱ�"] = "ʯ��ׯ",
["����"] = "֣��",
["������"] = "������",
["����"] = "�人",
["����"] = "��ɳ",
["����"] = "����",
["����"] = "�Ͼ�",
["����"] = "�ϲ�",
["����"] = "����",
["���ɹ�"] = "���ͺ���",
["����"] = "����",
["�ຣ"] = "����",
["ɽ��"] = "����",
["ɽ��"] = "̫ԭ",
["����"] = "����",
["�Ϻ�"] = "�Ϻ�",
["�Ĵ�"] = "�ɶ�",
["���"] = "���",
["����"] = "����",
["�½�"] = "��³ľ��",
["����"] = "����",
["�㽭"] = "����",
["����"] = "����",

}

-- ZheJiangAY = {}
-- GuangDongAY = {}
PROVINCEARRAY = {
["����"] = AnHuiAY,
["����"] = BeiJingAY,
["����"] = FuJianAY,
["����"] = GanSuAY,
["�㶫"] = GuangDongAY,
["����"] = GuangXiAY,
["����"] = GuiZhouAY,
["����"] = HaiNanAY,
["�ӱ�"] = HeBeiAY,
["����"] = HeNanAY,
["������"] = HeiLongJiangAY,
["����"] = HuBeiAY,
["����"] = HuNanAY,
["����"] = JiLinAY,
["����"] = JiangSuAY,
["����"] = JiangXiAY,
["����"] = LiaoNingAY,
["���ɹ�"] = NeiMengGuAY,
["����"] = NingXiaAY,
["�ຣ"] = QingHaiAY,
["ɽ��"] = ShanDongAY,
["ɽ��"] = ShanXiAY,
["����"] = SHANXIAY,
["�Ϻ�"] = ShangHaiAY,
["�Ĵ�"] = SiChuanAY,
["���"] = TianJinAY,
["����"] = TibetAY,
["�½�"] = XinJiangAY,
["����"] = YunNanAY,
["�㽭"] = ZheJiangAY,
["����"] = ChongQingAY,
}




eop_province = {
["����"] = 29,
["����"] = 0,
["����"] = 17,
["����"] = 27,
["�㶫"] = 18,
["����"] = 19,
["����"] = 20,
["����"] = 30,
["�ӱ�"] = 8,
["����"] = 9,
["������"] = 6,
["����"] = 13,
["����"] = 12,
["����"] = 5,
["����"] = 15,
["����"] = 14,
["����"] = 4,
["���ɹ�"] = 7,
["����"] = 25,
["�ຣ"] = 24,
["ɽ��"] = 10,
["ɽ��"] = 11,
["����"] = 26,
["�Ϻ�"] = 1,
["�Ĵ�"] = 22,
["���"] = 2,
["����"] = 23,
["�½�"] = 28,
["����"] = 21,
["�㽭"] = 16,
["����"] = 3,
}



-- select phonenum, locationid from numtabmob where phonenum=(select max(phonenum) from numtabmob where phonenum= '1881'or phonenum='18811' or phonenum='188110' or phonenum='1881101'or phonenum='18811016');