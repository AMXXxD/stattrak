#include <amxmodx>
#include <amxmisc>
#include <fvault>

enum _:TopRecord (+= 1) { NAME[33], WEAPON_ID, KILLS };
	
new g_sBuffer[2048] = ""
new Array:records, bool: g_reset, bool: g_connect[33];
new const stattrak[] = "STATTRAK";
 
new const g_szTop[][][]={
	{"#ff0000", "http://i.imgur.com/ls15RO5.png"},
	{"#07fcff", "http://i.imgur.com/TkLidPg.png"},
	{"#fff007", "http://i.imgur.com/VlgI5rT.png"}
};
 
new const weaponIndexes[][]={
	{CSW_KNIFE, "NOZ"},
	{CSW_AK47, "AK47"},
	{CSW_M4A1, "M4A1"},
	{CSW_AWP, "AWP"},
	{CSW_SCOUT, "SCOUT"},
	{CSW_DEAGLE, "DEAGLE"},
	{CSW_USP, "USP"},
	{CSW_GLOCK18, "GLOCK18"},
	{CSW_P228, "P228"},
	{CSW_XM1014, "XM1014"},
	{CSW_MAC10, "MAC10"},
	{CSW_AUG, "AUG"},
	{CSW_ELITE, "ELITE"},
	{CSW_FIVESEVEN, "FIVESEVEN"},
	{CSW_UMP45, "UMP45"},
	{CSW_SG550, "SG550"},
	{CSW_FAMAS, "FAMAS"},
	{CSW_GALIL, "GALIL"},
	{CSW_MP5NAVY, "MP5NAVY"},
	{CSW_M249, "M249"},
	{CSW_M3, "M3"},
	{CSW_TMP, "TMP"},
	{CSW_G3SG1, "G3SG1"}, 
	{CSW_SG552, "SG552"},
	{CSW_P90, "P90"},
	{CSW_HEGRENADE, "HE"}
};
 
new userStatTrak[33][25];
 
public plugin_init(){
	register_plugin("Stattrak", "2.1", "aSior edit. PANDA");
   
	register_clcmd("say /stattrak", "statTrak");
	register_clcmd("say /st", "statTrak");
	register_clcmd("say_team /stattrak", "statTrak");
	register_clcmd("say_team /st", "statTrak");
	register_concmd("amx_reset_stattrak", "reset_stattrak");
	
	register_logevent("Koniec_Rundy", 2, "1=Round_End");
	register_event("DeathMsg", "DeathMsg", "a");
	g_reset = false;
}

public plugin_natives(){
 	register_native("StatTrak", "Native_StatTrak");
}

public client_putinserver(id){
	readData(id);
	g_connect[id] = true;
}

public client_disconnected(id){
	if(!g_reset && g_connect[id]){
		saveData(id);
		g_connect[id] = false;
	}
}

public DeathMsg(){
	new kid = read_data(1);
	new vid = read_data(2);	
	new weapon[64]		
	read_data(4,weapon,63);
	if (!is_user_connected(vid) || !is_user_connected(kid) || kid == vid){
		return;
	}
	
	for(new i=0; i < sizeof(weaponIndexes); i++){
		if(containi(weapon, weaponIndexes[i][1])!=-1){
			userStatTrak[kid][i]++;
			break
		}
	}
}
 
public Koniec_Rundy(){
	if(!g_reset){
		new Players[32], Num;
		get_players_ex(Players, Num, GetPlayers_None);
		for(new i=0; i < Num; i++){
			saveData(Players[i]);
		}
	}
}

public Native_StatTrak(plugin, params){
	new id = get_param(1);
	statTrak(id);
}
	
public statTrak(id){
	new menu = menu_create("StatTrak", "menuhandle");
	menu_additem(menu, "Twoj StatTrak");
	menu_additem(menu, "Online StatTrak");
	menu_additem(menu, "TOP15 StatTrak");
	menu_additem(menu, "Twoj Rank StatTrak");

	menu_setprop(menu, MPROP_EXITNAME, "Wyjscie");
	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public menuhandle(id, menu, item){	
	switch(item) {
		case 0: statTrakMenu(id, id);
		case 1: statTrakMenuOnline(id);
		case 2: show_top(id);
		case 3: show_rank(id, id);
	}
	menu_destroy(menu); 
	return PLUGIN_HANDLED;
}

public statTrakMenuOnline(id){
	new menu = menu_create("Lista Graczy:", "menustattrak_handler"), maxplayers = get_maxplayers(), name[32], data[6];
	new ilosc=0;
	for(new i=1; i<=maxplayers; i++){
		if(!is_user_connected(i) || is_user_hltv(i) || is_user_bot(i) || i == id) continue;
		num_to_str(i, data, 5);
		get_user_name(i, name, 31);
		menu_additem(menu, name, data);
		ilosc+=1;
	}
	if(ilosc==0) client_print_color(id, id, "^4[StatTrak]^1 Nie ma kogo pokazac.");
	menu_setprop(menu, MPROP_EXITNAME, "Powrot");
	menu_display(id, menu);
	return PLUGIN_HANDLED;
}

public menustattrak_handler(id, menu, item){
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;
		
	if(item==MENU_EXIT){
		statTrak(id);
		return PLUGIN_HANDLED;
	}
	new name[32], callback, data[6], dostep;
	menu_item_getinfo(menu, item, dostep, data, 5, name, 31, callback);
	new target = str_to_num(data);
	if(!is_user_connected(target))
		return PLUGIN_HANDLED;
		
	statTrakMenu(id, target);
	show_rank(id, target);
	
	menu_destroy(menu); 
	return PLUGIN_HANDLED;
}

public statTrakMenu(id, target){
	new menu = menu_create("Stattrak:", "statTrakMenu_handler"), item[48], menuCallback = menu_makecallback("blockOptions");
 
	for(new i=0; i < sizeof(weaponIndexes); i++){
		formatex(item, charsmax(item), "\r%s \w--> \yZabojstwa: %i", weaponIndexes[i][1], userStatTrak[target][i]);
		if(userStatTrak[target][i] > 0){
			menu_additem(menu, item, _, _, menuCallback);
		}
	}
 
	menu_setprop(menu, MPROP_EXITNAME, "Powrot");
	menu_display(id, menu);
 
	return PLUGIN_HANDLED;
}
 
public statTrakMenu_handler(id, menu, item){
	if(item==MENU_EXIT){
		statTrak(id);
	}
	menu_destroy(menu); 
	return PLUGIN_HANDLED;
}
 
public blockOptions(id, menu, item){
	return ITEM_DISABLED;
}

saveData(id){
	new vaultKey[33], vaultData[64];
	get_user_name(id, vaultKey, charsmax(vaultKey));
   
	for(new i=0; i < sizeof(weaponIndexes); i++){
		formatex(vaultData, charsmax(vaultData), "%s%i#", vaultData, userStatTrak[id][i]);
	}
	fvault_set_data(stattrak, vaultKey, vaultData);
}
 
readData(id){
	new vaultKey[33], vaultData[64], intValues[30][30];
	get_user_name(id, vaultKey, charsmax(vaultKey));
 
	fvault_get_data(stattrak, vaultKey, vaultData, charsmax(vaultData));
	explode(vaultData, '#', intValues, charsmax(intValues), sizeof(weaponIndexes))
 
	for(new i=0; i < sizeof(weaponIndexes); i++){
		userStatTrak[id][i] = str_to_num(intValues[i]);
	}
}

stock explode(const string[],const character,output[][],const maxs,const maxlen){
	new iDo = 0,
	len = strlen(string),
	oLen = 0;
 
	do{
		oLen += (1+copyc(output[iDo++],maxlen,string[oLen],character))
	}
	while(oLen < len && iDo < maxs)
}

public show_rank(id, target){
	new rank, kills, weapon, found = get_my_rank(target, rank, kills, weapon);
	
	if(!found){
		if(id == target) client_print_color(id, id, "^4[StatTrak]^1Nie znaleziono twojego rankingu.");
		else client_print_color(id, id, "^4[StatTrak]^1Nie znaleziono tego rankingu.");
		return;
	}
	else {
		if(id == target)
			client_print_color(id, id, "^4[StatTrak]^1 Twoj ranking StatTrak wynosi ^3%i ^1na ^3%i^1. Masz ^3%i ^1killi z ^3%s^1.", rank, ArraySize(records), kills, weaponIndexes[weapon][1]);
		else  client_print_color(id, id, "^4[StatTrak]^1 Ranking StatTrak wynosi ^3%i ^1na ^3%i^1. Ma ^3%i ^1killi z ^3%s^1.", rank, ArraySize(records), kills, weaponIndexes[weapon][1]);
	}
}

public show_top(id){
	records = read_records();
	ArraySort(records, "by_most_kills");
	format_top15(g_sBuffer)
	show_motd(id, g_sBuffer, "Top 15 StatTrak")

	return PLUGIN_HANDLED;
}

get_my_rank(target, &rank, &kills, &weapon){
	if(!is_user_connected(target)){
		return 0;
	}
 
	new name[MAX_NAME_LENGTH + 1], record[TopRecord];
	
	records = read_records();
	ArraySort(records, "by_most_kills");
	get_user_name(target, name, charsmax(name));
	
	for(new i = 0; i < ArraySize(records) - 1; i++){
		ArrayGetArray(records, i, record);
 
		if(equal(name, record[NAME])){
			rank = i + 1;
			kills = record[KILLS];
			weapon = record[WEAPON_ID];
 
			return 1;
		}
	}
	return 0;
}

Array:read_records(){
	new Array:output = ArrayCreate(TopRecord, 1);
	new Array:keys = ArrayCreate(MAX_NAME_LENGTH + 4, 1);
	new Array:datas = ArrayCreate(200, 1);
	new total = fvault_load(stattrak, keys, datas);

	if(!total){
		return output;
	}

	new key[MAX_NAME_LENGTH+4], data[200], dummy_record[TopRecord];

	for(new i = 0; i < total; i++)
	{
		ArrayGetString(keys, i, key, charsmax(key));
		ArrayGetString(datas, i, data, charsmax(data));

		new buffers[sizeof(weaponIndexes)][10];

		explode_string(data, "#", buffers, sizeof(buffers), charsmax(buffers[]));

		copy(dummy_record[NAME], MAX_NAME_LENGTH, key);

		for(new j = 0; j < sizeof(weaponIndexes); j++){
			dummy_record[WEAPON_ID] = j;
			dummy_record[KILLS] = str_to_num(buffers[j]);
			if(dummy_record[KILLS] > 0){
				ArrayPushArray(output, dummy_record);
			}
		}
	}
	return output;
}

public by_most_kills(Array:array, id_a, id_b){
	new item_a[TopRecord], item_b[TopRecord];

	ArrayGetArray(array, id_a, item_a);
	ArrayGetArray(array, id_b, item_b);

	if(item_a[KILLS] < item_b[KILLS]) return 1;
	if(item_a[KILLS] > item_b[KILLS]) return -1;

	return 0;
}

format_top15(sBuffer[2048]){
	new record[TopRecord], iLen=0;
	
	iLen = format(sBuffer, 2047, "<body bgcolor=#000000><font color=#FFB000><pre>")
	iLen += format(sBuffer[iLen], 2047 - iLen, "%s %-23.23s %6s %7s^n", "#", "Nick", "Kille", "Bron")
	
	for (new i = 0; i < 15; i++){        
		ArrayGetArray(records, i, record);
		if(i < sizeof(g_szTop)){
			iLen += format(sBuffer[iLen], 2047 - iLen, "<font color=%s>%d %-22.22s %6d  %10s  <img src=^"%s^"/></font>^n", g_szTop[i][0], i+1, record[NAME], record[KILLS], weaponIndexes[record[WEAPON_ID]][1], g_szTop[i][1])
		} 
		else{
			iLen += format(sBuffer[iLen], 2074 - iLen, "%d %-22.22s %6d  %10s^n", i + 1, record[NAME], record[KILLS], weaponIndexes[record[WEAPON_ID]][1])
		}
		if(i==ArraySize(records)-1) break;
	}
}

public reset_stattrak(id){
	if(get_user_flags(id) & ADMIN_RCON){
		new g_resetmenu;
		g_resetmenu = menu_create("Jestes pewny?", "resetmenuhandle");
		menu_additem(g_resetmenu, "Nie");
		menu_additem(g_resetmenu, "Tak");

		menu_setprop(g_resetmenu, MPROP_EXITNAME, "Wyjscie");
		menu_display(id, g_resetmenu);
	}
	else{
		console_print(id, "Nie masz dostepu do tej komendy.")
	}
	return PLUGIN_HANDLED;
}

public resetmenuhandle(id, menu, item){ 
	if(item==1){
		new nick[33];
		get_user_name(id, nick, charsmax(nick));
		g_reset = true;
		fvault_clear(stattrak);
		client_print_color(id, id, "^4[StatTrak]^1 Wykonano reset StatTrak");
		log_amx("%s wykonal reset StatTrak", nick);
	}

	return PLUGIN_HANDLED;
}
