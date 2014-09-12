Rem
	====================================================================
	File contains game specific constants.

	Keep this in sync with the external database so exports wont
	break things apart.
	====================================================================
EndRem	
SuperStrict

Type TVTNewsType
	const SingleNews:int = 0
	const InitialNewsAutomatic:int = 1
	const InitialNewsInGameEvent:int = 2
	const FollowingNews:int =3
End Type


Type TVTNewsHandling
	const FixMessage:Int = 1
	const DynamicMessage:Int = 2
End Type


Type TVTNewsGenre
	const Politics_Economy:int = 0
	const ShowBiz:int = 1
	const Sport:int = 2
	const Technics_Media:int = 3
	const CurrentAffairs:int = 4
End Type


Type TVTNewsEffect
	const None:int = 0
	const ChangeMaxAudience:int = 1
	const ChangeTrend:int = 2
	const TerroristAttack:int = 4
End Type

	
Type TVTProgrammeType
	const Undefined:int = 0
	const Movie:int = 1
	const Series:int = 2
	const Show:int = 3
	const Reportage:int = 4
	const Commercial:int = 5
	const CallIn:int = 6
	const Event:int = 7
	const Misc:int = 8
End Type


Type TVTProgrammeGenre
	const Undefined:int = 0
 
	'Movie-Genre 1+
	const Adventure:int = 1
	const Action:int = 2
	const Animation:int = 3
	const Biography:int = 4
	const Crime:int = 5
	const Comedy:int = 6
	const Documentary:int = 7
	const Drama:int = 8
	const Erotic:int = 9
	const Family:int = 10
	const Fantasy:int = 11
	const History:int = 12
	const Horror:int = 13
	const Monumental:int = 14
	const Mystery:int = 15
	const Romance:int = 16
	const SciFi:int = 17
	const Thriller:int = 18
	const War:int = 19
	const Western:int = 20
 
	'Show-Genre 100+
	const Undefined_Show:int = 200

	'Event-Genre 200+
	const Politics:int = 201 'Wahlen, Große Reden, Bundestagsdebatte
	const Music:int = 202 'AC/DC-Konzert
	const Sport:int = 203 'Fussball WM, Olymische Spiele
	const Showbiz:int = 204 'Oscarverleihung, Golden Globes, Gala-Abend
 
	'Reportage-Genre 300+
	const Undefined_Reportage:int = 300
	const YellowPress:int = 301
End Type


Type TVTProgrammeFlag
	const Live:Int = 1		'Genereller Quotenbonus!
	const Animation:Int = 2	'Bonus bei Kindern / Jugendlichen. Malues bei Rentnern / Managern.
	const Culture:Int = 4	'Bonus bei Betty und bei Managern
	const Cult:Int = 8		'Verringert die Nachteile des Filmalters. Bonus bei Rentnern. Höhere Serientreue bei Serien.
	const Trash:Int = 16	'Bonus bei Arbeitslosen und Hausfrauen. Malus bei Arbeitnehmern und Managern. Trash läuft morgens und mittags gut => Bonus!
	const BMovie:Int = 32	'Nochmal deutlich verringerter Preis. Verringert die Nachteile des Filmalters. Bonus bei Jugendlichen. Malus bei allen anderen Zielgruppen. Bonus in der Nacht!
	const XRated:Int = 64	'Kleiner Bonus für Jugendliche, Arbeitnehmer, Arbeitslose, (Männer). Kleiner Malus für Kinder, Hausfrauen, Rentner, (Frauen).
	const Paid:Int = 128	'Call-In-Shows
	const Series:Int = 256	'Ist ne Serie! Vielleicht besser als den ProgrammeType... so kann auch ne Reportage ne Serie sein.
End Type


Type TVTTargetGroup
	const All:int = 0
	const Children:int = 1
	const Teenagers:int = 2
	const HouseWifes:int = 3
	const Employees:int = 4
	const Unemployed:int = 5
	const Manager:int = 6
	const Pensioners:int = 7
	const Women:int = 8
	const Men:int = 9
End Type


Type TVTPressureGroup
	const None:int = 0
	const SmokerLobby:int = 1
	const AntiSmoker:int = 2
	const ArmsLobby:int = 4
	const Pacifists:int = 8
	const Capitalists:int = 16
	const Communists:int = 32
End Type