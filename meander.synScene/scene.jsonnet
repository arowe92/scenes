local width = 1260;
local height = 168;

// local width = ;
// local height = 10;

{
	"CONTROLS" :
	[
		{
			"DEFAULT" : 0.5,
			"DESCRIPTION" : "",
			"MAX" : 1,
			"MIN" : 0,
			"NAME" : "Slider1",
			"TYPE" : "slider",
			"UI_GROUP" : "vars"
		},
		{
			"DEFAULT" : 1,
			"DESCRIPTION" : "",
			"MAX" : 1,
			"MIN" : 0,
			"NAME" : "Slider2",
			"TYPE" : "slider",
			"UI_GROUP" : "vars"
		},
		{
			"DEFAULT" : 0,
			"DESCRIPTION" : "",
			"MAX" : 1,
			"MIN" : 0,
			"NAME" : "Slider3",
			"TYPE" : "slider",
			"UI_GROUP" : "vars"
		},
		{
			"DEFAULT" : 1,
			"DESCRIPTION" : "",
			"MAX" : 2,
			"MIN" : 0,
			"NAME" : "Slider4",
			"TYPE" : "slider",
			"UI_GROUP" : "vars"
		},
		{
			"DEFAULT" : 0,
			"DESCRIPTION" : "",
			"MAX" : 1,
			"MIN" : 0,
			"NAME" : "MouseXY",
			"TYPE" : "xy",
			"UI_GROUP" : "defaults"
		},
		{
			"DEFAULT" : 0,
			"DESCRIPTION" : "",
			"MAX" : 1,
			"MIN" : 0,
			"NAME" : "MouseClick",
			"TYPE" : "toggle",
			"UI_GROUP" : "defaults"
		}
	],
	"CREDIT" : "wyatt",
	"DESCRIPTION" : "meandering currents",
	// "HEIGHT" : height,
	// "WIDTH" : width,
	"IMAGE_PATH" : "meander.png",
	"PASSES" :
	[
		{
			"FLOAT" : true,
			"HEIGHT" : height,
			"TARGET" : "BuffA",
			"WIDTH" : width
		},
		{
			"FLOAT" : true,
			"HEIGHT" : height,
			"TARGET" : "BuffB",
			"WIDTH" : width
		},
		{
			"FLOAT" : true,
			"HEIGHT" : height,
			"TARGET" : "BuffC",
			"WIDTH" : width
		},
		{
			"FLOAT" : true,
			"HEIGHT" : height,
			"TARGET" : "BuffD",
			"WIDTH" : width
		}
	],
	"TITLE" : "Meander",
}
