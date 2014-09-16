Rem
	====================================================================
	AdContract data - contracts of broadcastable advertisements
	====================================================================

	The normal contract data is splitted into "contractBase" and
	"contract". So the resulting contract can differ to the raw database
	contract (eg. discounts, special prices...). Also you can have the
	same contract data with different ids ... so multiple incarnations
	of a contract are possible.
EndRem
SuperStrict
Import "game.gameobject.bmx"
Import "game.world.worldtime.bmx"
'to fetch maximum audience
Import "game.stationmap.bmx"
Import "game.broadcastmaterial.base.bmx"



Type TAdContractBaseCollection
	Field entries:TMap = CreateMap()
	Field entriesCount:int = -1
	Global _instance:TAdContractBaseCollection


	Function GetInstance:TAdContractBaseCollection()
		if not _instance then _instance = new TAdContractBaseCollection
		return _instance
	End Function


	Method GetByGUID:TAdContractBase(GUID:String)
		Return TAdContractBase(entries.ValueForKey(GUID))
	End Method

	'this is not guaranteed to be unique!
	Method GetByTitle:TAdContractBase(title:String, language:String="")
		For Local base:TAdContractBase = EachIn entries.Values()
			If base.title.Get(language) = title Then Return base
		Next
		Return Null
	End Method


	Method Get:TAdContractBase(id:Int)
		For Local base:TAdContractBase = EachIn entries.Values()
			If base.id = id Then Return base
		Next
		Return Null
	End Method


	Method GetCount:Int()
		if entriesCount >= 0 then return entriesCount

		entriesCount = 0
		For Local base:TAdContractBase = EachIn entries.Values()
			entriesCount :+1
		Next
		return entriesCount
	End Method


	Method GetRandom:TAdContractBase(array:TAdContractBase[] = null)
		if array = Null or array.length = 0 then array = GetAllAsArray()
		If array.length = 0 Then Return Null

		Return array[(randRange(0, array.length-1))]
	End Method


	Method GetAllAsArray:TAdContractBase[]()
		local array:TAdContractBase[]
		'create a full array containing all elements
		For local obj:TAdContractBase = EachIn entries.Values()
			array :+ [obj]
		Next
		return array
	End Method


	Method GetRandomWithLimitedAudienceQuote:TAdContractBase(minAudienceQuote:float=0.0, maxAudienceQuote:Float=0.35)
		'maxAudienceQuote - xx% market share as maximum
		'filter to entries we need
		Local array:TAdContractBase[]
		For local obj:TAdContractBase = EachIn entries.Values()
			If obj.minAudienceBase >= minAudienceQuote AND obj.minAudienceBase <= maxAudienceQuote
				array :+ [obj]
			EndIf
		Next
		Return GetRandom(array)
	End Method


	Method Remove:int(obj:TAdContractBase)
		if obj.GetGuid() and entries.Remove(obj.GetGUID())
			'invalidate count
			entriesCount = -1

			return True
		endif

		return False
	End Method


	Method Add:int(obj:TAdContractBase)
		entries.Insert(obj.GetGUID(), obj)
		'invalidate count
		entriesCount = -1

		return True
	End Method


	Method RefreshInfomercialTopicalities:int() {_private}
		For Local base:TAdContractBase = eachin entries.Values()
			base.RefreshInfomercialTopicality()
		Next
	End Method
End Type
	
'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetAdContractBaseCollection:TAdContractBaseCollection()
	Return TAdContractBaseCollection.GetInstance()
End Function




Type TAdContractCollection
	Field list:TList = CreateList()
	Global _instance:TAdContractCollection


	Function GetInstance:TAdContractCollection()
		if not _instance then _instance = new TAdContractCollection
		return _instance
	End Function


	Method Get:TAdContract(id:Int)
		For Local contract:TAdContract = EachIn list
			If contract.id = id Then Return contract
		Next
		Return Null
	End Method


	Method Remove:int(obj:TAdContract)
		return list.Remove(obj)
	End Method


	Method Add:int(obj:TAdContract)
		'only add once
		if list.contains(obj) then return False
		
		list.AddLast(obj)
		return TRUE
	End Method
End Type

'===== CONVENIENCE ACCESSOR =====
'return collection instance
Function GetAdContractCollection:TAdContractCollection()
	Return TAdContractCollection.GetInstance()
End Function





'contracts bases for advertisement - straight from the DB
'they just contain data to base new contracts of
Type TAdContractBase extends TGameObject {_exposeToLua}
	Field title:TLocalizedString
	Field description:TLocalizedString
	'days to fullfill a (signed) contract
	Field daysToFinish:Int
	'spots to send
	Field spotCount:Int = 1
	'block length
	Field blocks:int = 1
	'target group of the spot
	Field limitedToTargetGroup:Int
	'is the ad broadcasting limit to a specific genre?
	'eg. "horror"
	Field limitedToGenre:Int = -1
	'is the ad broadcasting limit to a specific programme type?
	'eg. "series", "movies"
	Field limitedToProgrammeType:Int = -1
	'is the ad broadcasting limit to a specific programme genre?
	'eg. only "lovestory"
	Field limitedToProgrammeGenre:Int = -1
	'is the ad broadcasting not allowed for a specific programme genre?
	'eg. no "lovestory"
	Field forbiddenProgrammeGenre:Int = -1
	'is the ad broadcasting not allowed for a specific programme type?
	'eg. no "series"
	Field forbiddenProgrammeType:Int = -1

	'is the ad broadcasting limit to a specific broadcast type?
	'Field limitedToBroadcastType:Int = -1

	'are there a interest groups liking/hating broadcasts of this?
	'eg. anti-nicotin
	Field proPressureGroups:Int = -1
	Field contraPressureGroups:Int = -1
	
	'minimum audience (real value calculated on sign)
	Field minAudienceBase:Float
	'minimum image base value (real value calculated on sign)
	Field minImageBase:Float
	'flag wether price is fixed or not
	Field fixedPrice:Int = False
	'base of profit (real value calculated on sign)
	Field profitBase:Float
	'base of penalty (real value calculated on sign)
	Field penaltyBase:Float
	'the quality of the advertisement (cheap one or hollywood style?)
	'also might affect infomercial audience rating
	Field quality:Float = 0.5 'default is 50%
	'=== infomercials / shopping shows ===
	'is the broadcast of an infomercial allowed?
	Field infomercialAllowed:int = TRUE
	'topicality for this contract base (all adcontracts of this base
	'share this topicality !)
	Field infomercialTopicality:float = 1.0
	Field infomercialMaxTopicality:float = 1.0

	'by which factor do we cut the profit when send as infomercial
	'compared to the profit a single ad would generate
	'- for all
	Global infomercialCutFactor:Float = 0.2
	Global infomercialCutFactorDevModifier:Float = 1.0
	'- for the individual base
	'Field infomercialCutFactorModifier:Float = 1.0

	Const TARGETGROUP_CHILDREN:Int = 1
	Const TARGETGROUP_TEENAGER:Int = 2
	Const TARGETGROUP_HOUSEWIFES:Int = 3
	Const TARGETGROUP_EMPLOYEES:Int = 4
	Const TARGETGROUP_UNEMPLOYED:Int = 5
	Const TARGETGROUP_MANAGER:Int = 6
	Const TARGETGROUP_PENSIONERS:Int = 7
	Const TARGETGROUP_WOMEN:Int = 8
	Const TARGETGROUP_MEN:Int = 9


	Method Create:TAdContractBase(GUID:String, title:TLocalizedString, description:TLocalizedString, daysToFinish:Int, spotCount:Int, targetgroup:Int, minAudience:Float, minImage:Float, fixedPrice:Int, profit:Float, penalty:Float)
		self.SetGUID(GUID)
		self.title = title
		self.description = description
		self.daysToFinish = daysToFinish
		self.spotCount = spotCount
		self.limitedToTargetGroup = targetGroup
		self.minAudienceBase = minAudience
		self.minImageBase = minImage
		self.fixedPrice = fixedPrice
		self.profitBase	= profit
		self.penaltyBase = penalty

		GetAdContractBaseCollection().Add(self)

		Return self
	End Method


	Method GetTitle:string() {_exposeToLua}
		if title then return title.Get()
	End Method


	Method GetDescription:string() {_exposeToLua}
		if description then return description.Get()
		return ""
	End Method


	Method GetBlocks:int() {_exposeToLua}
		return blocks
	End Method


	Method GetQuality:int() {_exposeToLua}
		return quality
	End Method


	Method GetInfomercialTopicality:Float() {_exposeToLua}
		return infomercialTopicality
	End Method


	Method GetMaxInfomercialTopicality:Float() {_exposeToLua}
		return infomercialMaxTopicality
	End Method


	Method CutInfomercialTopicality:Int(cutFactor:float=1.0) {_private}
		infomercialTopicality :* cutFactor
		'limit to 0-max
		infomercialTopicality = Max(0, Min(infomercialTopicality, GetMaxInfomercialTopicality()))
	End Method


	Method GetProPressureGroups:int()
		return proPressureGroups
	End Method


	Method HasProPressureGroup:Int(group:Int) {_exposeToLua}
		Return proPressureGroups & group
	End Method


	Method SetProPressureGroup:int(group:int, enable:int=True)
		If enable
			proPressureGroups :| group
		Else
			proPressureGroups :& ~group
		EndIf
	End Method


	Method GetContraPressureGroups:int()
		return contraPressureGroups
	End Method


	Method HasContraPressureGroup:Int(group:Int) {_exposeToLua}
		Return contraPressureGroups & group
	End Method


	Method SetContraPressureGroup:int(group:int, enable:int=True)
		If enable
			contraPressureGroups :| group
		Else
			contraPressureGroups :& ~group
		EndIf
	End Method



	Method RefreshInfomercialTopicality:Int() {_private}
		'each day topicality refreshes by 15%
		infomercialTopicality :* 1.15
		'limit to 0-max
		infomercialTopicality = Max(0, Min(infomercialTopicality, GetMaxInfomercialTopicality()))
		Return infomercialTopicality
	End Method
End Type




'the useable contract for advertisements used in the playercollections
Type TAdContract extends TNamedGameObject {_exposeToLua="selected"}
	'holds raw contract data
	Field base:TAdContractBase = Null
	'how many spots were successfully sent up to now
	Field spotsSent:Int = 0
	'how many spots were planned up to now
	Field spotsPlanned:Int = 0
	'day the contract has been taken from the advertiser-room
	Field daySigned:Int = -1
	'calculated profit value (on sign)
	Field profit:Int = -1
	'calculated penalty value (on sign)
	Field penalty:Int = -1
	'calculated minimum audience value (on sign)
	Field minAudience:Int = -1
	' KI: Wird nur in der Lua-KI verwendet du die Filme zu bewerten
	Field attractiveness:Float = -1



	Method New()
		GetAdContractCollection().Add(self)
	End Method
	

	'create UNSIGNED (adagency)
	Method Create:TAdContract(baseContract:TAdContractBase)
		self.base = baseContract

		GetAdContractCollection().Add(self)
		Return self
	End Method


	'what to earn each hour for each viewer
	'(broadcasted as "infomercial")
	Method GetPerViewerRevenue:Float() {_exposeToLua}
		if not isInfomercialAllowed() then return 0.0

		local result:float = 0.0

		'calculate
		result = GetProfit() / GetSpotCount()
		result :* 0.001 'way down for reasonable prices
		'so currently we end up with the price equal to
		'the price of a successful contract / GetSpotCount()

		'now cut this to the given infomercialCutFactor
		result :* TAdContractBase.infomercialCutFactor
		result :* TAdContractBase.infomercialCutFactorDevModifier
		'cut again with the individual cut factor
		'result :* base.infomercialCutFactorModifier

		'less revenue with less topicality
		if base.GetMaxInfomercialTopicality() > 0
			result :* (base.infomercialTopicality / base.GetMaxInfomercialTopicality())
		endif
		return result
	End Method


	'overwrite method from base
	Method GetTitle:string() {_exposeToLua}
		Return base.GetTitle()
	End Method


	'overwrite method from base
	Method GetDescription:string() {_exposeToLua}
		Return base.GetDescription()
	End Method


	'overwrite method from base
	Method GetBlocks:int() {_exposeToLua}
		Return base.GetBlocks()
	End Method


	'sign the contract -> calculate values and change owner
	Method Sign:int(owner:int, day:int=-1)
		if self.owner = owner then return FALSE

		'attention: GetProfit/GetPenalty/GetMinAudience default to "owner"
		'           if we set the owner BEFORE, the functions wont use
		'           the "average" of all players -> set owner afterwards
		self.profit	= GetProfit()
		self.penalty = GetPenalty()
		self.minAudience = GetMinAudience()

		self.owner = owner
		If day < 0 Then day = GetWorldTime().GetDay()
		self.daySigned = day

		'TLogger.log("TAdContract.Sign", "Player "+owner+" signed a contract.  Profit: "+profit+",  Penalty: "+penalty+ ",  MinAudience: "+minAudience+",  Title: "+GetTitle(), LOG_DEBUG)
		return TRUE
	End Method


	Method IsAvailableToSign:Int() {_exposeToLua}
		'maybe add other checks here - even if something
		'is not signed yet, it might not be able to get signed...
		Return (not IsSigned())
	End Method


	Method IsSigned:int() {_exposeToLua}
		return (owner > 0 and daySigned >= 0)
	End Method


	'percents = 0.0 - 1.0 (0-100%)
	Method GetMinAudiencePercentage:Float(dbvalue:Float = -1) {_exposeToLua}
		If dbvalue < 0 Then dbvalue = Self.base.minAudienceBase
		Return MathHelper.Clamp(dbValue, 0.0, 1.0)
	End Method


	'the quality is higher for "better paid" advertisements with
	'higher audience requirements... no cheap "car seller" ad :D
	Method GetQuality:Float(luckFactor:Int = 1) {_exposeToLua}
		Local quality:Float = 0.05

		if GetMinAudience() >   1000 then quality :+ 0.01		'+0.06
		if GetMinAudience() >   5000 then quality :+ 0.025		'+0.085
		if GetMinAudience() >  10000 then quality :+ 0.05		'+0.135
		if GetMinAudience() >  50000 then quality :+ 0.075		'+0.21
		if GetMinAudience() > 250000 then quality :+ 0.1		'+0.31
		if GetMinAudience() > 750000 then quality :+ 0.19		'+0.5
		if GetMinAudience() >1500000 then quality :+ 0.25		'+0.75
		if GetMinAudience() >5000000 then quality :+ 0.25		'+1.00

		If luckFactor = 1 Then
			quality = quality * 0.98 + Float(RandRange(10, 20)) / 1000.0 '1%-Punkte bis 2%-Punkte Basis-Qualität
		Else
			quality = quality * 0.99 + 0.01 'Mindestens 1% Qualität
		EndIf

		'no minus quote
		quality = Max(0, quality)
		Return quality
	End Method


	Method isInfomercialAllowed:int() {_exposeToLua}
		return base.infomercialAllowed
	End Method


	'if targetgroup is set, the price is doubled
	Method GetProfit:Int(playerID:Int= -1) {_exposeToLua}
		'already calculated and data for owner requested
		If playerID=-1 and profit >= 0 Then Return profit

		'calculate
		Return CalculatePrices(base.profitBase, playerID)
	End Method


	'returns the penalty for this contract
	Method GetPenalty:Int(playerID:Int=-1) {_exposeToLua}
		'already calculated and data for owner requested
		If playerID=-1 and penalty >= 0 Then Return penalty

		'calculate
		Return CalculatePrices(base.penaltyBase, playerID)
	End Method


	'calculate prices (profits, penalties...)
	Method CalculatePrices:Int(baseValue:Float=0, playerID:Int=-1) {_exposeToLua}
		'=== FIXED PRICE ===
		'ad is with fixed price - only available without minimum restriction
		If base.fixedPrice
			'print self.base.title.Get() + " has fixed price : "+ int(baseValue * GetSpotCount()) + " base:"+int(baseprice) + " profitbase:"+base.profitBase +" penaltyBase:"+base.penaltyBase
			'basePrice is a precalculated value (eg. 1000 euro)
			Return baseValue * GetSpotCount()
		endif


		'=== DYNAMIC PRICE ===
		'maximum value for
		'spotCount = 1
		'baseValue/profit/penalty = 100%,
		'minAudience = 100%
		'maxAudience = 80 000 000 (whole Germany)
		'baseCPM * baseValue * spotcount * minAudienceInNumbers
		'baseCPM * 1.0       * 1         * (80 000 000 * 1.0)
		'= baseCPM * 80 000 000

		Local devConfig:TData = TData(GetRegistry().Get("DEV_CONFIG", new TData.Init()))
		'baseCPM is a balancing factor!
		Local balancingFactor:float = devConfig.GetFloat("DEV_AD_BALANCING_FACTOR", 1.0)
		Local minCPM:float = devConfig.GetFloat("DEV_AD_MINIMUM_CPM", 7.5)
		Local limitedToGenreMultiplier:float = devConfig.GetFloat("DEV_AD_LIMITED_GENRE_MULTIPLIER", 2.0)
		Local limitedToTargetGroupMultiplier:float = devConfig.GetFloat("DEV_AD_LIMITED_TARGETGROUP_MULTIPLIER", 2.0)
		Local price:Float

		'1) calculate a CPM-Value: a value paid "per 1000 viewer"

		'baseValue is "baseCPM" here, a value paid for 1000 viewers
		price = baseValue * GetSpotCount()
		'adjust by a balancing factor
		price :* balancingFactor

		'specific targetgroups change price
		If GetLimitedToTargetGroup() > 0 Then price :* limitedToTargetGroupMultiplier
		'limiting to specific genres change the price too
		If GetLimitedToGenre() > 0 Then price :* limitedToGenreMultiplier

		'2) calculate final value by multiplying with required audience 
		'To avoid "dumping prices" we do at least multiply with "minCPM"
		'or higher
		price :* Max(minCPM, getRawMinAudience(playerID)/1000)

		'print GetTitle()+": "+GetMinAudiencePercentage() +" -- price " +price +" ---raw audience "+getRawMinAudience(playerID)

		'3) return "beautiful" prices
		Return TFunctions.RoundToBeautifulValue(price)
	End Method


	'returns the non rounded minimum audience
	Method GetRawMinAudience:Int(playerID:int=-1) {_exposeToLua}
		'if no special player is requested -
		if playerID <= 0 and IsSigned() then playerID = owner
		'if contract has no owner the avg audience maximum is returned
		local useAudience:int = 0
		if playerID <= 0
			useAudience = GetStationMapCollection().GetAverageReach()
		else
			useAudience = GetStationMapCollection().GetMap(playerID).GetReach()
		endif

		'no more than 50 percent of whole germany will watch TV at the
		'same time, so convert "whole germany watches"-based audience
		'percentage to a useable one:
		'cut it by 0.5
		Return Floor(0.5 * useAudience * GetMinAudiencePercentage())
	End Method


	'Gets minimum needed audience in absolute numbers
	Method GetMinAudience:Int(playerID:int=-1) {_exposeToLua}
		'already calculated and data for owner requested
		If playerID=-1 and minAudience >=0 Then Return minAudience

		Return TFunctions.RoundToBeautifulValue( GetRawMinAudience(playerID) )
	End Method


	'days left for sending all contracts from today
	Method GetDaysLeft:Int() {_exposeToLua}
		Return ( base.daysToFinish - (GetWorldTime().GetDay() - daySigned) )
	End Method


	'get the contract (to access its ID or title by its GetXXX() )
	Method GetBase:TAdContractBase() {_exposeToLua}
		Return base
	End Method


	'returns whether the contract was fulfilled
	Method isSuccessful:int() {_exposeToLua}
		Return (base.spotCount <= spotsSent)
	End Method


	'amount of spots still missing
	Method GetSpotsToSend:int() {_exposeToLua}
		Return (base.spotCount - spotsSent)
	End Method


	Method SetSpotsPlanned:int(value:int)
		spotsPlanned = value
	End Method


	'amount of spots planned (adjusted by programmeplanner)
	Method GetSpotsPlanned:int() {_exposeToLua}
		return spotsPlanned
	End Method


	'amount of spots which have already been successfully broadcasted
	Method GetSpotsSent:int() {_exposeToLua}
		Return spotsSent
	End Method


	'amount of total spots to send
	Method GetSpotCount:Int() {_exposeToLua}
		Return base.spotCount
	End Method


	'total days to send contract from date of sign
	Method GetDaysToFinish:Int() {_exposeToLua}
		Return base.daysToFinish
	End Method


	Method GetLimitedToTargetGroup:Int() {_exposeToLua}
		Return base.limitedToTargetGroup
	End Method


	Method GetLimitedToTargetGroupString:String(group:Int=-1) {_exposeToLua}
		'if no group given, use the one of the object
		if group < 0 then group = self.base.limitedToTargetGroup

		If group >= 1 And group <=9
			Return GetLocale("AD_GENRE_"+group)
		else
			Return GetLocale("AD_GENRE_NONE")
		EndIf
	End Method


	Method GetLimitedToGenre:Int() {_exposeToLua}
		Return base.limitedToGenre
	End Method


	Method ShowSheet:Int(x:Int,y:Int, align:int=0, showMode:int=0)
		'set default mode
		if showMode = 0 then showMode = TBroadcastMaterial.TYPE_ADVERTISEMENT

		if KeyManager.IsDown(KEY_LALT) or KeyManager.IsDown(KEY_RALT)
			if showMode = TBroadcastMaterial.TYPE_PROGRAMME
				showMode = TBroadcastMaterial.TYPE_ADVERTISEMENT
			else
				showMode = TBroadcastMaterial.TYPE_PROGRAMME
			endif
		Endif

		if showMode = TBroadcastMaterial.TYPE_PROGRAMME
			ShowInfomercialSheet(x, y, align)
		elseif showMode = TBroadcastMaterial.TYPE_ADVERTISEMENT
			ShowAdvertisementSheet(x, y, align)
		endif
	End Method


	Method ShowInfomercialSheet:Int(x:Int,y:Int, align:int=0)
		'=== DRAW BACKGROUND ===
		local sprite:TSprite
		local currX:Int = x
		local currY:int = y

		'move sheet to left when right-aligned
		if align = 1 then currX = x - GetSpriteFromRegistry("gfx_datasheet_title").area.GetW()
		
		sprite = GetSpriteFromRegistry("gfx_datasheet_title"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_series"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_content"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_subTop"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		if owner > 0
			sprite = GetSpriteFromRegistry("gfx_datasheet_subMessageEarn"); sprite.Draw(currX, currY)
			currY :+ sprite.GetHeight()
		endif
		sprite = GetSpriteFromRegistry("gfx_datasheet_subTopicalityRating"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_bottom"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()



		'=== DRAW TEXTS / OVERLAYS ====
		currY = y + 8 'so position is within "border"
		currX :+ 7 'inside
		local textColor:TColor = TColor.CreateGrey(25)
		local textLightColor:TColor = TColor.CreateGrey(75)
		local textEarnColor:TColor = TColor.Create(45,80,10)
		Local fontNormal:TBitmapFont = GetBitmapFontManager().baseFont
		Local fontBold:TBitmapFont = GetBitmapFontManager().baseFontBold
		Local fontSemiBold:TBitmapFont = GetBitmapFontManager().Get("defaultThin", -1, BOLDFONT)

		GetBitmapFontManager().Get("default", 13, BOLDFONT).drawBlock(GetTitle(), currX + 6, currY, 280, 17, ALIGN_LEFT_CENTER, textColor, 0,1,1.0,True, True)
		currY :+ 18
		fontNormal.drawBlock(GetLocale("INFOMERCIAL"), currX + 6, currY, 280, 15, ALIGN_LEFT_CENTER, textColor, 0,1,1.0,True, True)
		currY :+ 16

		'content description
		currY :+ 3	'description starts with offset
		fontNormal.drawBlock(getLocale("AD_INFOMERCIAL"), currX + 6, currY, 280, 64, null ,textColor)
		currY :+ 64 'content
		currY :+ 3	'description ends with offset

		currY :+ 4 'offset of subContent

		if owner > 0
			'convert back cents to euros and round it
			'value is "per 1000" - so multiply with that too
			local revenue:string = TFunctions.DottedValue(int(1000 * GetPerViewerRevenue()))+CURRENCYSIGN
			currY :+ 4 'top content padding of that line
			fontSemiBold.drawBlock(getLocale("MOVIE_CALLINSHOW").replace("%PROFIT%", revenue), currX + 35,  currY, 245, 15, ALIGN_CENTER_CENTER, textEarnColor, 0,1,1.0,True, True)
			currY :+ 15 + 8 'lineheight + bottom content padding
		endif
		
		'topicality
		fontSemiBold.drawBlock(GetLocale("MOVIE_TOPICALITY"), currX + 215, currY, 75, 15, null, textLightColor)

		if base.GetInfomercialTopicality() > 0.1
			SetAlpha GetAlpha()*0.25
			GetSpriteFromRegistry("gfx_datasheet_bar").DrawResized(new TRectangle.Init(currX + 8, currY + 1, 200, 10))
			SetAlpha GetAlpha()*4.0
			GetSpriteFromRegistry("gfx_datasheet_bar").DrawResized(new TRectangle.Init(currX + 8, currY + 1, base.GetInfomercialTopicality()*200, 10))
		endif
	End Method


	Method ShowAdvertisementSheet:Int(x:Int,y:Int, align:int=0)
		'=== DRAW BACKGROUND ===
		local sprite:TSprite
		local currX:Int = x
		local currY:int = y
		local daysLeft:int = GetDaysLeft()
		'not signed?
		if owner <= 0 then daysLeft = GetDaysToFinish()

		'move sheet to left when right-aligned
		if align = 1 then currX = x - GetSpriteFromRegistry("gfx_datasheet_title").area.GetW()
		
		sprite = GetSpriteFromRegistry("gfx_datasheet_title"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_content"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_subTop"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()

		'warn if special target group
		If base.limitedToTargetGroup > 0
			sprite = GetSpriteFromRegistry("gfx_datasheet_subMessageTargetGroup"); sprite.Draw(currX, currY)
			currY :+ sprite.GetHeight()
		EndIf

		'warn if short of time
		If daysLeft <= 1
			sprite = GetSpriteFromRegistry("gfx_datasheet_subMessageWarning"); sprite.Draw(currX, currY)
			currY :+ sprite.GetHeight()
		EndIf

		sprite = GetSpriteFromRegistry("gfx_datasheet_subAdContractAttributes"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()
		sprite = GetSpriteFromRegistry("gfx_datasheet_bottom"); sprite.Draw(currX, currY)
		currY :+ sprite.GetHeight()



		'=== DRAW TEXTS / OVERLAYS ====
		currY = y + 8 'so position is within "border"
		currX :+ 7 'inside
		local textColor:TColor = TColor.CreateGrey(25)
		local textProfitColor:TColor = TColor.Create(45,80,10)
		local textPenaltyColor:TColor = TColor.Create(80,45,10)
		local textWarningColor:TColor = TColor.Create(80,45,10)
		Local fontNormal:TBitmapFont = GetBitmapFontManager().baseFont
		Local fontBold:TBitmapFont = GetBitmapFontManager().baseFontBold
		Local fontSemiBold:TBitmapFont   = GetBitmapFontManager().Get("defaultThin", -1, BOLDFONT)


		GetBitmapFontManager().Get("default", 13, BOLDFONT).drawBlock(GetTitle(), currX + 6, currY, 280, 17, ALIGN_LEFT_CENTER, textColor, 0,1,1.0,True, True)
		currY :+ 18

		'content description
		currY :+ 3	'description starts with offset
		fontNormal.drawBlock(GetDescription(), currX + 6, currY, 280, 64, null ,textColor)
		currY :+ 64 'content
		currY :+ 3	'description ends with offset

		currY :+ 4 'offset of subContent


		'warn if special target group
		If base.limitedToTargetGroup > 0
			currY :+ 4 'top content padding of that line
			fontSemiBold.drawBlock(getLocale("AD_TARGETGROUP")+": "+GetLimitedToTargetGroupString(), currX + 35, currY, 245, 15, ALIGN_CENTER_CENTER, textWarningColor, 0,1,1.0,True, True)
			currY :+ 15 + 8 'lineheight + bottom content padding
		Endif

		'warn if short of time
		If daysLeft <= 1
			currY :+ 4 'top content padding of that line
			If daysLeft = 1
				fontSemiBold.drawBlock(getLocale("AD_SEND_TILL_TOMORROW"), currX + 35, currY, 245, 15, ALIGN_CENTER_CENTER, textWarningColor, 0,1,1.0,True, True)
			ElseIf daysLeft = 0
				fontSemiBold.drawBlock(getLocale("AD_SEND_TILL_MIDNIGHT"), currX + 35, currY, 245, 15, ALIGN_CENTER_CENTER, textWarningColor, 0,1,1.0,True, True)
			Else
				fontSemiBold.drawBlock(getLocale("AD_SEND_TILL_TOLATE"), currX + 35, currY, 245, 15, ALIGN_CENTER_CENTER, textWarningColor, 0,1,1.0,True, True)
			EndIf
			currY :+ 15 + 8 'lineheight + bottom content padding
		Endif


		currY :+ 4 'align to content portion of that line
		'days left for this contract
		If daysLeft > 1
			fontBold.drawBlock(daysLeft +" "+ getLocale("DAYS"), currX+34, currY , 62, 15, ALIGN_CENTER_CENTER, textColor, 0,1,1.0,True, True)
		Else
			fontBold.drawBlock(daysLeft +" "+ getLocale("DAY"), currX+34, currY , 62, 15, ALIGN_CENTER_CENTER, textColor, 0,1,1.0,True, True)
		EndIf
		'spots successfully sent
		if owner < 0
			'show how many we have to send
			fontBold.drawBlock(GetSpotCount() + "x", currX+131, currY , 58, 15, ALIGN_CENTER_CENTER, textColor, 0,1,1.0,True, True)
		else
			fontBold.drawBlock(GetSpotsSent() + "/" + GetSpotCount(), currX+131, currY , 58, 15, ALIGN_CENTER_CENTER, textColor, 0,1,1.0,True, True)
		endif
		'planend
		if owner > 0
			fontBold.drawBlock(GetSpotsPlanned() + "/" + GetSpotCount(), currX+224, currY , 58, 15, ALIGN_CENTER_CENTER, textColor, 0,1,1.0,True, True)
		endif
		currY :+ 15 + 8 'lineheight + bottom content padding


		currY :+ 4 'align to content portion of that line
		'minAudience
		fontBold.drawBlock(TFunctions.convertValue(GetMinAudience(), 2), currX+33, currY , 66, 15, ALIGN_CENTER_CENTER, textColor, 0,1,1.0,True, True)
		'penalty
		fontBold.drawBlock(TFunctions.convertValue(GetPenalty(), 2), currX+131, currY , 58, 15, ALIGN_RIGHT_CENTER, textPenaltyColor, 0,1,1.0,True, True)
		'profit
		fontBold.drawBlock(TFunctions.convertValue(GetProfit(), 2), currX+224, currY , 58, 15, ALIGN_RIGHT_CENTER, textProfitColor, 0,1,1.0,True, True)
		currY :+ 15 + 8 'lineheight + bottom content padding
	End Method


	'===== AI-LUA HELPER FUNCTIONS =====

	'Wird bisher nur in der LUA-KI verwendet
	Method GetAttractiveness:Float() {_exposeToLua}
		Return Self.attractiveness
	End Method


	'Wird bisher nur in der LUA-KI verwendet
	Method SetAttractiveness(value:Float) {_exposeToLua}
		Self.attractiveness = value
	End Method


	'Wird bisher nur in der LUA-KI verwendet
	'Wie hoch ist das finanzielle Gewicht pro Spot?
	'Wird dafür gebraucht um die Wichtigkeit des Spots zu bewerten
	Method GetFinanceWeight:float() {_exposeToLua}
		Return (self.GetProfit() + self.GetPenalty()) / self.GetSpotCount()
	End Method


	'Wird bisher nur in der LUA-KI verwendet
	'Berechnet wie Zeitkritisch die Erfüllung des Vertrages ist (Gesamt)
	Method GetPressure:float() {_exposeToLua}
		local _daysToFinish:int = self.GetDaysToFinish() + 1 'In diesem Zusammenhang nicht 0-basierend
		Return self.GetSpotCount() / _daysToFinish * _daysToFinish
	End Method


	'Wird bisher nur in der LUA-KI verwendet
	'Berechnet wie Zeitkritisch die Erfüllung des Vertrages ist (tatsächlich / aktuell)
	Method GetCurrentPressure:float() {_exposeToLua}
		local _daysToFinish:int = self.GetDaysToFinish() + 1 'In diesem Zusammenhang nicht 0-basierend
		Return self.GetSpotsToSend() / _daysToFinish * _daysToFinish
	End Method


	'Wird bisher nur in der LUA-KI verwendet
	'Wie dringend ist es diese Spots zu senden
	Method GetAcuteness:float() {_exposeToLua}
		Local spotsToBroadcast:int = self.GetSpotCount() - self.GetSpotsToSend()
		Local daysLeft:int = self.getDaysLeft() + 1 'In diesem Zusammenhang nicht 0-basierend
		If daysLeft <= 0 then return 0 'no "acuteness" for obsolete contracts
		Return spotsToBroadcast  / daysLeft * daysLeft  * 100
	End Method


	'Wird bisher nur in der LUA-KI verwendet
	'Wie viele Spots sollten heute mindestens gesendet werden
	Method SendMinimalBlocksToday:int() {_exposeToLua}
		Local spotsToBroadcast:int = self.GetSpotCount() - self.GetSpotsToSend()
		Local acuteness:int = self.GetAcuteness()
		Local daysLeft:int = self.getDaysLeft() + 1 'In diesem Zusammenhang nicht 0-basierend
		If daysLeft <= 0 then return 0 'no "blocks" for obsolete contracts

		If (acuteness >= 100)
			Return int(spotsToBroadcast / daysLeft) 'int rundet
		Elseif (acuteness >= 70)
			Return 1
		Else
			Return 0
		Endif
	End Method


	'Wird bisher nur in der LUA-KI verwendet
	'Wie viele Spots sollten heute optimalerweise gesendet werden
	Method SendOptimalBlocksToday:int() {_exposeToLua}
		Local spotsToBroadcast:int = self.GetSpotCount() - self.GetSpotsToSend()
		Local daysLeft:int = self.getDaysLeft() + 1 'In diesem Zusammenhang nicht 0-basierend
		If daysLeft <= 0 then return 0 'no "blocks" for obsolete contracts

		Local acuteness:int = self.GetAcuteness()
		Local optimumCount:int = Int(spotsToBroadcast / daysLeft) 'int rundet

		If (acuteness >= 100) and (spotsToBroadcast > optimumCount)
			optimumCount = optimumCount + 1
		Endif

		If (acuteness >= 100)
			return Int(spotsToBroadcast / daysLeft)  'int rundet
		Endif
	End Method
	'===== END AI-LUA HELPER FUNCTIONS =====
End Type
