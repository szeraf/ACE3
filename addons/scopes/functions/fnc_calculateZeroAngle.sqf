/*
 * Author: Ruthberg
 * Calculates the required zero angle for the given zero range with respect to the bore height (distance between bore- and sight axis)
 *
 * Arguments:
 * 0: Zero range <NUMBER>
 * 1: Bore height <NUMBER>
 * 2: Weapon <OBJECT>
 * 3: Ammo <CLASS>
 * 4: Magazine <CLASS>
 * 5: Advanced Ballistics enabled? <BOOL>
 *
 * Return Value:
 * zeroAngleCorrection <NUMBER>
 *
 * Example:
 * [5, 6, gun, ammo, magazine, true] call ace_scopes_fnc_calculateZeroAngle
 *
 * Public: No
 */
#include "script_component.hpp"

params ["_zeroRange", "_boreHeight"/*in cm*/, "_weapon", "_ammo", "_magazine", "_advancedBallistics"];

private _airFriction = getNumber (configFile >> "CfgAmmo" >> _ammo >> "airFriction");
private _initSpeed = getNumber(configFile >> "CfgMagazines" >> _magazine >> "initSpeed");
private _initSpeedCoef = getNumber(configFile >> "CfgWeapons" >> _weapon >> "initSpeed");
if (_initSpeedCoef > 0) then {
    _initSpeed = _initSpeedCoef;
};
if (_initSpeedCoef < 0) then {
    _initSpeed = _initSpeed * (-1 * _initSpeedCoef);
};

private _trueZero = if (!_advancedBallistics) then {
    private _zeroAngle = "ace_advanced_ballistics" callExtension format ["zeroAngleVanilla:%1:%2:%3:%4", _zeroRange, _initSpeed, _airFriction, _boreHeight];
    (parseNumber _zeroAngle)
} else {
    // Get Weapon and Ammo Configurations
    private _AmmoCacheEntry = uiNamespace getVariable format[QEGVAR(advanced_ballistics,%1), _ammo];
    if (isNil "_AmmoCacheEntry") then {
         _AmmoCacheEntry = _ammo call EFUNC(advanced_ballistics,readAmmoDataFromConfig);
    };
    private _WeaponCacheEntry = uiNamespace getVariable format[QEGVAR(advanced_ballistics,%1), _weapon];
    if (isNil "_WeaponCacheEntry") then {
         _WeaponCacheEntry = _weapon call EFUNC(advanced_ballistics,readWeaponDataFromConfig);
    };

    _AmmoCacheEntry params ["_airFriction", "_caliber", "_bulletLength", "_bulletMass", "_transonicStabilityCoef", "_dragModel", "_ballisticCoefficients", "_velocityBoundaries", "_atmosphereModel", "_ammoTempMuzzleVelocityShifts", "_muzzleVelocityTable", "_barrelLengthTable"];
    _WeaponCacheEntry params ["_barrelTwist", "_twistDirection", "_barrelLength"];

    if (missionNamespace getVariable [QEGVAR(advanced_ballistics,barrelLengthInfluenceEnabled), false]) then {
        private _barrelVelocityShift = [_barrelLength, _muzzleVelocityTable, _barrelLengthTable, _initSpeed] call EFUNC(advanced_ballistics,calculateBarrelLengthVelocityShift);
        _initSpeed = _initSpeed + _barrelVelocityShift;
    };

    private _zeroAngle = "ace_advanced_ballistics" callExtension format ["zeroAngle:%1:%2:%3:%4:%5:%6:%7:%8:%9", _zeroRange, _initSpeed, _boreHeight, GVAR(zeroReferenceTemperature), GVAR(zeroReferenceBarometricPressure), GVAR(zeroReferenceHumidity), _ballisticCoefficients select 0, _dragModel, _atmosphereModel];
    (parseNumber _zeroAngle)
};

missionNamespace setVariable [format[QGVAR(%1_%2_%3_%4_%5_%6), _zeroRange, _boreHeight, _weapon, _ammo, _magazine, _advancedBallistics], _trueZero];

_trueZero
