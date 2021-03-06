if CLIENT then
	SWEP.PrintName			= "USP .45"			
	SWEP.Author				= "Counter-Strike"
	SWEP.Slot				= 1
	SWEP.SlotPos			= 0
	SWEP.IconLetter			= "a"
	
	killicon.AddFont( "weapon_usp", "CSKillIcons", SWEP.IconLetter, Color( 255, 80, 0, 255 ) )
elseif SERVER then
	AddCSLuaFile()
end

SWEP.HoldType			= "pistol"
SWEP.Base				= "weapon_cs_base"
SWEP.Category			= "Counter-Strike"

SWEP.Spawnable			= true
SWEP.AdminSpawnable		= true

SWEP.ViewModel 			= "models/weapons/v_pist_usp.mdl"
SWEP.WorldModel 			= "models/weapons/w_pist_usp.mdl"

SWEP.Weight				= 5
SWEP.AutoSwitchTo		= false
SWEP.AutoSwitchFrom		= false

SWEP.Primary.Sound 		= Sound("Weapon_USP.Single")
SWEP.Primary.SilencedSound = Sound( "Weapon_USP.Silencedshot" )
SWEP.Primary.Damage 		= 20
SWEP.Primary.Recoil 		= 0 --1
SWEP.Primary.NumShots 		= 1
SWEP.Primary.Cone 		= 0.0155
SWEP.Primary.ClipSize 		= 12
SWEP.Primary.Delay 		= 0.16
SWEP.Primary.DefaultClip 	= 12
SWEP.Primary.Automatic 		= false
SWEP.Primary.Ammo 		= "pistol"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "none"

SWEP.IronSightsPos 		= Vector (4.4777, 0, 2.752)
SWEP.IronSightsAng 		= Vector (-0.2267, -0.0534, 0)

function SWEP:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end
	
	self.Weapon:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
	self.Weapon:SetNextSecondaryFire( CurTime() + self.Primary.Delay )

	local silenced = self:Var( "GetPrivate", "Type", false ) == true
	if CLIENT and not GunSoundsDisabled then
		self.Weapon:EmitSound( silenced and self.Primary.SilencedSound or self.Primary.Sound, 1 )
	end
	
	self:CSShootBullet( self.Primary.Damage, self.Primary.Recoil, self.Primary.NumShots, silenced and 0 or self.Primary.Cone )
	self:TakePrimaryAmmo( 1 )
	
	if self.Owner:IsNPC() then return end
	
	if silenced then
		self.Weapon:SendWeaponAnim( ACT_VM_PRIMARYATTACK_SILENCED )
	else
		self.Weapon:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
	end
end

function SWEP:SecondaryAttack()
	if self.NextSecondaryAttack > CurTime() then return end
	if not IsValid( self.Owner ) then return end
	
	if self:Var( "GetPrivate", "Type", false ) == true then
		self:Var( "SetPrivate", "Type", false, self.Owner )
		self.Weapon:SendWeaponAnim( ACT_VM_DRAW )
	else
		self:Var( "SetPrivate", "Type", true, self.Owner )
		self.Weapon:SendWeaponAnim( ACT_VM_DRAW_SILENCED )
	end
	
	self.NextSecondaryAttack = CurTime() + 2
end

function SWEP:Reload()
	if self:Var( "GetPrivate", "Type", false ) == true then
		self.Weapon:DefaultReload( ACT_VM_RELOAD_SILENCED )
	else
		self.Weapon:DefaultReload( ACT_VM_RELOAD )
	end
end