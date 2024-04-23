global function dq_strafemeterPrecache
//global function dq_strafemeterSettings

void function dq_strafemeterPrecache() {
    #if CLIENT
    strafemeterInit()
    #endif
}

#if CLIENT

vector function GetConVarFloat3(string convar){
    array<string> value = split(GetConVarString(convar), " ")
    try{
        return Vector(value[0].tofloat(), value[1].tofloat(), value[2].tofloat()) 
    }
    catch(ex){
        throw "Invalid convar " + convar + "! make sure it is a float3 and formatted as \"X Y Z\""
    }
    unreachable
}

var strafemeter = null
var strafemeterIndicator = null

void function strafemeterInit() {
    dq_createStrafemeter()
    AddCallback_EntitiesDidLoad(dq_strafemeterUpdate)
}

void function dq_createStrafemeter() {
    strafemeter = CreatePermanentCockpitRui($"ui/cockpit_console_text_top_left.rpak")
    RuiSetFloat2(strafemeter, "msgPos", GetConVarFloat3("dq_strafemeter_position"))
    RuiSetFloat(strafemeter, "msgAlpha", GetConVarFloat("dq_strafemeter_alpha"))
    RuiSetFloat3(strafemeter, "msgColor", <1.0, 1.0, 1.0>)

    strafemeterIndicator = CreatePermanentCockpitRui($"ui/cockpit_console_text_top_left.rpak")
    RuiSetFloat2(strafemeterIndicator, "msgPos", GetConVarFloat3("dq_strafemeter_position") + <0.0, 0.04, 0.0>)
    RuiSetFloat(strafemeterIndicator, "msgAlpha", GetConVarFloat("dq_strafemeter_alpha"))
    RuiSetFloat3(strafemeterIndicator, "msgColor", <1.0, 1.0, 1.0>)

    RuiSetString(strafemeterIndicator, "msgText", "|")

}

void function dq_strafemeterUpdate() {
    entity player
    vector strafemeterEyeVector
    vector strafemeterVelocity
    int strafemeterAcceleration
    float precosStrafeAngle
    float optimalStrafeAngle
    float optimalLook
    float currentStrafeAngle
    float angleDiff
    while (true) {
        WaitFrame()

        player = GetLocalViewPlayer()

        if (player == null || !IsValid(player)) {
            continue
        }

        strafemeterEyeVector = player.EyeAngles()
        strafemeterVelocity = player.GetVelocity()

        // only use X & Y axis
        strafemeterVelocity = < strafemeterVelocity.x, strafemeterVelocity.y, 0 >
        
        // get acceleration unit vector that is relevent to strafing
        strafemeterAcceleration = 0
        if (player.IsInputCommandHeld(IN_MOVELEFT)) {
            strafemeterAcceleration = -1
        }
        if (player.IsInputCommandHeld(IN_MOVERIGHT)) {
            strafemeterAcceleration = 1
        }

        //precosStrafeAngle = (60.0 - fabs(1.0/60.0*500.0))/strafemeterVelocity.Length()

        precosStrafeAngle = ((60.0 - 10.0) / strafemeterVelocity.Length()) // sv_airspeed = 60, with 10u margin
    
        if (fabs(precosStrafeAngle) < 1.0) {
            optimalStrafeAngle = fabs(asin(precosStrafeAngle)) * 180 / PI
        } else {
            optimalStrafeAngle = 0.0
        }
        // full equation is |asin(airspeeed / velocity)| -> degrees

        // velocity + 90deg +- optimal (depending on input held)
        optimalLook = (-atan2(strafemeterVelocity.x, strafemeterVelocity.y) * 180 / PI + 90 + (optimalStrafeAngle * strafemeterAcceleration))

        //making optimal look vector sane (-180, 180]
        if (optimalLook > 180.0) {
            optimalLook -= 360.0
        }

        if (optimalLook <= -180.0) {
            optimalLook += 360.0
        }

        angleDiff = optimalLook - strafemeterEyeVector.y
        
        RuiSetString(strafemeter, "msgText", "======^======\n\n======^======\n"
        // debug info, remove eventually?
        + strafemeterEyeVector.y.tostring() + "\n" + optimalLook.tostring() + "\n" + angleDiff.tostring())

        // setting position of position mter
        RuiSetFloat2(strafemeterIndicator, "msgPos", GetConVarFloat3("dq_strafemeter_position") + <0.055 + angleDiff * 0.01, 0.035, 0.0>)
    }
}


#endif
