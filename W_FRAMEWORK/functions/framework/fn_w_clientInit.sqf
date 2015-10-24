params ["_mode"];
_mode = toLower _mode;
switch _mode do {
	case "postinit": {
		isHC = !isNil "paramsArray" && {paramsArray select 0 == 1 && !hasInterface};
		if (isHC) then { call compile preprocessFileLineNumbers "initHC.sqf" };
		0 call FETT_fnc_w_setVariables;

		["ACE_moduleMedicalSettings","ACE_moduleAdvancedMedicalSettings","ACE_moduleReviveSettings"] call FETT_fnc_w_checkForbiddenObjects;

		// HC can exit now
		if (!hasInterface) exitWith {};

		private "_missingDLCs";
		_missingDLCs = getDLCs 2;
		// noHeli || noMarksman
		if (304380 in _missingDLCs || 332350 in _missingDLCs) then {
			[name player] remoteExecCall ["FETT_fnc_w_dlcMissing",0];
			["dlcMissing"] call BIS_fnc_endMission;
		};

		player addAction ["Viewdistance",{createDialog "W_RscVDDialog";}];

		// Get all settings
		private "_settings";
		_settings = call compile preprocessFileLineNumbers "settings.sqf";
		_settings params ["_cfgLoadouts","_noMapCondition","_logFF"];

		// Apply loadout
		if (_cfgLoadouts) then {
			[player getVariable ["loadout",""],"",player] call FETT_fnc_applyCfgLoadout;
		} else {
			private "_fnc";
			_fnc = format ["FETT_fnc_%1_loadout",["b","i","c","o"] select ([west,independent,civilian,east] find side player)];
			_fnc = missionNamespace getVariable _fnc;
			[(player getVariable ["loadout",""]),player] call _fnc;
		};

		// Remove map
		if (0 call _noMapCondition) then {
			[{
				if (!isNull (findDisplay 46)) then {
					player unlinkItem "ItemMap";
					[_this select 1] call CBA_fnc_removePerFramerHandler;
				};
			},0,[]] call CBA_fnc_addPerFrameHandler;
		};

		// Log friendly fire
		if (_logFF) then {
			player addEventHandler ["Hit",{
				params ["_target","_shooter","_damage"];
				if (isPlayer _shooter && {side _shooter == side _target} && {_shooter != _target}) then {
                    private ["_vicShooter", "_vicTarget"];
                    _vicShooter = "kein Fahrzeug";
                    _vicTarget = "kein Fahrzeug";
                    if (vehicle _shooter != _shooter) then {
                        _vicShooter = getText (configFile >> "CfgVehicles" >> (typeOf vehicle _shooter) >> "displayName");
                    };
                    if (vehicle _target != _target) then {
                        _vicTarget = getText (configFile >> "CfgVehicles" >> (typeOf vehicle _target) >> "displayName");
                    };
					(format [
                        "W_LOG_FRIENLDYFIRE: %1 (%6) %2 feuerte auf %3 (%7) %4 auf einer Distanz von %5m",
                        name _shooter,
                        getPosASL _shooter,
                        name _target,
                        getPosASL _target,
                        _shooter distance _target,
                        _vicShooter,
                        _vicTarget
                    ]) remoteExecCall ["diag_log",0];
				};
			}];
		};
	};
};
