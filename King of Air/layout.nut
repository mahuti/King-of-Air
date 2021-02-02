//
// King of Air
// Theme by Mahuti
// vs. 2.0 
// 
// shaders, scanlines by Yaron, thanks dude. 
//
local order = 0
class UserConfig {
    </ label="Rotate", 
		help="Controls how the layout should be rotated", 
		options="0,90,-90", 
		order=order++ /> 
		rotate="-90";
    </ label="Overlay Style", 
		help="Display King of Air or Air Attack style bezel overlay", 
		options="King of Air, Air Attack", 
		order=order++ /> 
		overlay="King of Air";

    </ label="Show CRT bloom or lottes shaders", 
        help="Enable bloom or lottes effects for the snap video, if user device supports GLSL shaders", 
        options="No,CRT Bloom,CRT Lottes", 
        order=order++  /> 
        enable_snap_shader="CRT Lottes";

    </ label="Show CRT screen glow ", 
		help="Enable screen glow effect for the snap video, if user device supports GLSL shaders", 
		options="No,Light,Medium,Strong", 
        order=order++ /> 
        enable_crt_screenglow="No";
    
    </ label="Show CRT scanlines", 
        help="Show CRT scanline effect", 
        options="No,Light,Medium,Dark", 
        order=order++ /> 
        enable_crt_scanline="Light";

    </ label="History.dat path",
        help="When using the King of Air layout, this shows the History/Info tab when a path is set here and History.dat plugin is also be enabled and working.",
        order=order++ />
        dat_path="";    
}

 
local config = fe.get_config()
fe.layout.font = "American Captain"

fe.load_module("preserve-art")
fe.do_nut(fe.script_dir + "modules/pos.nut" );

local enable_snap_shader = null
local scanlines_srf, crt_scanlines

// stretched positioning
local posData =  {
    base_width = 480.0,
    base_height = 640.0,
    layout_width = fe.layout.width,
    layout_height = fe.layout.height,
    scale= "stretch",
    rotate= 0
    debug = false,
}
local stretch = Pos(posData)

// scaled positioning
posData =  {
    base_width = 480.0,
    base_height = 640.0,
    layout_width = fe.layout.width,
    layout_height = fe.layout.height,
    scale= "scale",
    rotate= config["rotate"]
    debug = false,
}
local scale = Pos(posData)

if ( config["enable_snap_shader"] != "No" && ShadersAvailable == 1)
{
    if ( config["enable_snap_shader"] == "CRT Bloom")
    {
        enable_snap_shader="CRT Bloom"
    }

    if ( config["enable_snap_shader"] == "CRT Lottes")
    {
        enable_snap_shader = "CRT Lottes"
    }
}

local scroll_speed = 60 //time delay when moving content in milliseconds
local scroll_speed_with_delay = 2500 + scroll_speed
local scroll_speed_without_delay = scroll_speed 
scroll_speed = scroll_speed_with_delay
local last_time = 0 
local next_time = scroll_speed // time when movement should happen again
local rough_text_length = 0  // will be used to calculate lenght of text... crappily
local hist_msg_charcount = 0 // charcount of history message
    
local overlay= null 
local underlay = null 
if (config["overlay"]== "King of Air")
{
    overlay = fe.add_image("overlay.png", 0, 0, scale.width(480), scale.height(640))
    overlay.zorder=10
    overlay.x=scale.x(0,"center",overlay)
    overlay.y=scale.y(0,"center",overlay)

        
    underlay = fe.add_image("underlay.png",scale.x(306),scale.y(203), scale.width(137), scale.height(214)) 
    underlay.zorder=1
    underlay.x=scale.x(306,"left",underlay,overlay,"left")    
    underlay.y=scale.y(203,"top",underlay,overlay,"top")    
}
else
{
    overlay = fe.add_image("overlay2.png", 0, 0, scale.width(480), scale.height(640))
    overlay.zorder=10
    overlay.x=scale.x(0,"center",overlay)
    overlay.y=scale.y(0,"center",overlay)
}

    
local snap_surface = fe.add_surface( scale.width(221), scale.height(288) )
snap_surface.y=scale.y(121,"left",snap_surface,overlay,"left")
snap_surface.x=scale.x(37,"top",snap_surface,overlay,"top")
snap_surface.zorder=2
    
if (config["overlay"]== "Air Attack")
{
    snap_surface.x=scale.x(111,"top",snap_surface,overlay,"top")
    snap_surface.y=scale.y(104,"left",snap_surface,overlay,"left")
    snap_surface.width=scale.width(255)
    snap_surface.height=scale.height(345)
        
}


// list box background 
local list_box = fe.add_listbox( scale.x(22), scale.y(437), scale.width(264), scale.height(158) )
scale.set_font_height(18,list_box,"Left")
list_box.set_sel_rgb( 255, 226, 145 )
list_box.sel_alpha = 180
list_box.set_selbg_rgb(243,122,253)
list_box.selbg_alpha = 200
list_box.rows = 9
list_box.x=scale.x(22,"left",list_box,overlay,"left")    
list_box.y=scale.y(442,"top",list_box,overlay,"top")    
list_box.zorder=11 
list_box.align=Align.Left

if (config["overlay"]== "Air Attack")
{
    list_box.sel_alpha = 180
    list_box.set_sel_rgb(242,224,131)
    list_box.set_selbg_rgb(0,64,240)
    list_box.rows = 9
    list_box.width=scale.width(238)
    list_box.height=scale.height(137)
    list_box.x=scale.x(120,"left",list_box,overlay,"left")    
    list_box.y=scale.y(465,"top",list_box,overlay,"top")     
}


local fav_image = fe.add_image("star.png",0,0,scale.width(25),scale.height(25))
fav_image.y = scale.y(376,"top",fav_image,overlay,"top")
fav_image.x = scale.x(364,"left",fav_image,overlay,"left")
fav_image.alpha = 0
fav_image.zorder=12
local fav_content = "" 


function is_fav(index)
{
    if (fe.game_info(Info.Favourite,index)=="1"){
        fav_content = "• "
    }
    else
    {
        fav_content = "      " 
    }
    return fav_content
}



function set_favorite_graphic( ttype, var, ttime)
{
    if(ttype==Transition.FromOldSelection ||ttype==Transition.ToNewList)
    {
        if (fe.game_info(Info.Favourite)=="1"){
            fav_image.alpha=255 
        }
        else
        {
            fav_image.alpha = 0
        }
    }
        
    return false
}
fe.add_transition_callback( "set_favorite_graphic" )	

function select_sound( ttype, var, ttime ) 
{
 switch ( ttype ) {

  case Transition.ToNewSelection:
        local sound = fe.add_sound("game.mp3")
        sound.playing=true
        scroll_speed = scroll_speed_with_delay
        break
  }
 return false
}
fe.add_transition_callback( "select_sound" ) 
    
list_box.format_string =  fav_content + "[!is_fav][Title]"
// Snap
local snap = fe.add_surface( scale.width(221), scale.height(288) )
snap.x=scale.x(37,"left",snap_surface,overlay,"left")
snap.y=scale.y(121,"top",snap_surface,overlay,"top")
snap.zorder=2
    
if (config["overlay"]== "Air Attack")
{
    snap.x=scale.x(111,"left",snap_surface,overlay,"left")
    snap.y=scale.y(106,"top",snap_surface,overlay,"top")
    snap.width=scale.width(255)
    snap.height=scale.height(345)    
}

local snap_video = snap.add_artwork("snap", 0,0, scale.width(221), scale.height(288))
snap_video.preserve_aspect_ratio=true
if (config["overlay"]== "Air Attack")
{
    snap.width=scale.width(255)
    snap.height=scale.height(345)
}
snap_video.trigger = Transition.EndNavigation

snap.x=scale.x(0,"center",snap,snap_surface,"center")
snap.y=scale.y(7,"center",snap,snap_surface,"center")
snap.zorder = 3
 
if (config["overlay"]== "Air Attack")
{
    snap.y=scale.y(0,"center",snap,snap_surface,"center")
}

// snap shader effects 
if ( enable_snap_shader == "CRT Bloom" && ShadersAvailable == 1)
{
    local sh = fe.add_shader( Shader.Fragment, "shaders/bloom_shader.frag" );
    sh.set_texture_param("bgl_RenderedTexture"); 
    snap.shader = sh;
}

if ( enable_snap_shader == "CRT Lottes" && ShadersAvailable == 1)
{
    local shader_lottes = null;

    shader_lottes=fe.add_shader(
        Shader.VertexAndFragment,
        "shaders/CRT-geom.vsh",
        "shaders/CRT-geom.fsh");

    // APERATURE_TYPE
    // 0 = VGA style shadow mask.
    // 1.0 = Very compressed TV style shadow mask.
    // 2.0 = Aperture-grille.
    shader_lottes.set_param("aperature_type", 1.0);
    shader_lottes.set_param("hardScan", 0.0);   // Hardness of Scanline -8.0 = soft -16.0 = medium
    shader_lottes.set_param("hardPix", -2.0);     // Hardness of pixels in scanline -2.0 = soft, -4.0 = hard
    shader_lottes.set_param("maskDark", 0.9);     // Sets how dark a "dark subpixel" is in the aperture pattern.
    shader_lottes.set_param("maskLight", 0.3);    // Sets how dark a "bright subpixel" is in the aperture pattern
    shader_lottes.set_param("saturation", 1.1);   // 1.0 is normal saturation. Increase as needed.
    shader_lottes.set_param("tint", 0.0);         // 0.0 is 0.0 degrees of Tint. Adjust as needed.
    shader_lottes.set_param("distortion", 0.15);		// 0.0 to 0.2 seems right
    shader_lottes.set_param("cornersize", 0.04);  // 0.0 to 0.1
    shader_lottes.set_param("cornersmooth", 80);  // Reduce jagginess of corners
    shader_lottes.set_texture_param("texture");

    snap.shader = shader_lottes;

}
 
// scanline default
if (config["enable_crt_scanline"] != "No")
{
    local scan_art;

    scanlines_srf = fe.add_surface( fe.layout.width, fe.layout.height )
    scanlines_srf.set_pos( 0,0 );
    scanlines_srf.zorder=4
        
    if( ScreenWidth < 1920 )
    {
        scan_art = fe.script_dir + "scanlines_640.png"
    }
    else  // 1920 res or higher
    {
        scan_art = fe.script_dir + "scanlines_1920.png"
    }
    crt_scanlines = scanlines_srf.add_image( scan_art, snap_surface.x, snap_surface.y, snap_surface.width, snap_surface.height )
    crt_scanlines.preserve_aspect_ratio = false

    if( config["enable_crt_scanline"] == "Light" )
    {
        if( ScreenWidth < 1920 )
            crt_scanlines.alpha = 20
        else
            crt_scanlines.alpha = 50
    }
    if( config["enable_crt_scanline"] == "Medium" )
    {
        if( ScreenWidth < 1920 )
            crt_scanlines.alpha = 40
        else
            crt_scanlines.alpha = 100
    }
    if( config["enable_crt_scanline"] == "Dark" )
    {
        crt_scanlines.alpha = 200
    }
}
function set_crt_size()
{
    if (config["enable_crt_scanline"] != "No")
    {
        crt_scanlines.width = snap_surface.width
        crt_scanlines.height =snap_surface.height  
        crt_scanlines.x = snap_surface.x
        crt_scanlines.y = snap_surface.y
    }
}

/*
                if (enable_snap_shader)
                {
                    snap.shader.set_param("color_texture_sz", snap.width, snap.height);
                    snap.shader.set_param("color_texture_pow2_sz", snap.width, snap.height);
                }
      if ( ttype == Transition.EndNavigation || ttype == Transition.StartLayout || ttype==Transition.ToNewList || ttype==Transition.FromGame )

  */ 
if (ShadersAvailable == 1 && config["enable_crt_scanline"] !="No")
{
    fe.add_transition_callback( "shader_transitions" );    
}
function shader_transitions( ttype, var, ttime ) {
    switch ( ttype )
    {
    case Transition.ToNewList:	
    case Transition.EndNavigation:
        if (ShadersAvailable == 1 && config["enable_crt_scanline"] !="No")
        {
            snap.shader.set_param("color_texture_sz", snap.width, snap.height);
            snap.shader.set_param("color_texture_pow2_sz", snap.width, snap.height);
        }
        break;
    }
    return false;
}


set_crt_size()
   
//////////////////////////////////////////////////////////////////////////////////////////////////
// Shader - Screen Glow
// check if GLSL shaders are available on this system
if( config["enable_crt_screenglow"] != "No" && ShadersAvailable == 1 )
{
	// shadow parameters
	local shadow_radius = 1600;
	local shadow_xoffset = 0;
	local shadow_yoffset = 0;
	local shadow_alpha = 255;
	local shadow_downsample = 0;
	
	if( config["enable_crt_screenglow"] == "Light" )
	{
		shadow_downsample=0.04;
		shadow_xoffset = scale.x(300)
		shadow_yoffset = scale.y(300)
	}
	else if( config["enable_crt_screenglow"] == "Medium" )
	{
		shadow_downsample=0.03;
		shadow_xoffset = scale.x(200)
		shadow_yoffset = scale.y(250)
	}
	else if( config    ["enable_crt_screenglow"] == "Strong" )
	{
		shadow_downsample=0.02;
		shadow_xoffset = scale.x(100)
		shadow_yoffset = scale.y(150)
	}

	// creation of first surface with safeguards area
	local xsurf1 = fe.add_surface (shadow_downsample * (snap_video.width + 2*shadow_radius), shadow_downsample * (snap_video.height + 2*shadow_radius));
    xsurf1.zorder=12
        
	// add a clone of the picture to topmost surface
	local pic1 = xsurf1.add_clone(snap_video);
	pic1.set_pos(shadow_radius*shadow_downsample,shadow_radius*shadow_downsample,snap_video.width*shadow_downsample,snap_video.height*shadow_downsample);

	// creation of second surface
	local xsurf2 = fe.add_surface (xsurf1.width, xsurf1.height);
    xsurf2.zorder=13
        
	// nesting of surfaces
	xsurf1.visible = false;
	xsurf1 = xsurf2.add_clone(xsurf1);
    xsurf1.zorder=14
        
	xsurf1.visible = true;

	// define and apply blur shaders
	local blursizex = 1.0/xsurf2.width;
	local blursizey = 1.0/xsurf2.height;
	local kernelsize = shadow_downsample * (shadow_radius * 2) + 1;
	local kernelsigma = shadow_downsample * shadow_radius * 0.3;

	local shaderH1 = fe.add_shader( Shader.Fragment, fe.script_dir + "gauss_kernsigma_o.glsl" );
	shaderH1.set_texture_param( "texture");
	shaderH1.set_param("kernelData", kernelsize, kernelsigma);
	shaderH1.set_param("offsetFactor", blursizex, 0.0);
	xsurf1.shader = shaderH1;

	local shaderV1 = fe.add_shader( Shader.Fragment, fe.script_dir + "gauss_kernsigma_o.glsl" );
	shaderV1.set_texture_param( "texture");
	shaderV1.set_param("kernelData", kernelsize, kernelsigma);
	shaderV1.set_param("offsetFactor", 0.0, blursizey);
	xsurf2.shader = shaderV1;

	// apply black color and alpha channel to shadow
	pic1.alpha=shadow_alpha;
	pic1.width=21;
	pic1.height=16;

	// reposition and upsample shadow surface stack
	xsurf2.set_pos (snap_video.x-shadow_radius+shadow_xoffset,snap_video.y-shadow_radius+shadow_yoffset, snap_video.width + 2 * shadow_radius , snap_video.height + 2 * shadow_radius);
}

// Play Time
local playtime = fe.add_text("[PlayedTime]", scale.x(371),scale.y(151), scale.width(60), scale.height(15))
scale.set_font_height(13,playtime,"Left")
playtime.x = scale.x(372,"top",playtime,overlay,"top")
playtime.y = scale.y(156.2,"left",playtime,overlay,"left")
playtime.set_rgb(255, 255, 255)	
playtime.zorder=11

if (config["overlay"]== "Air Attack")
{
    playtime.x = scale.x(22,"left",playtime,overlay,"left")
    playtime.y = scale.y(555,"top",playtime,overlay,"top")
    playtime.width=scale.width(77)
    playtime.height=scale.height(33)
}

local page = fe.add_text("[!current_page]", scale.x(371),scale.y(177), scale.width(60), scale.height(15))
scale.set_font_height(13,page,"Left")
page.x = scale.x(372,"top",page,overlay,"top")
page.y = scale.y(186,"left",page,overlay,"left")
page.set_rgb(255, 255, 255)	
page.zorder=12

if (config["overlay"]== "Air Attack")
{
    page.width=scale.width(77)
    page.height=scale.height(33)
    page.x = scale.x(22,"left",page,overlay,"left")
    page.y = scale.y(437,"top",page,overlay,"top")
        
    scale.set_font_height(15,playtime,"Left")
    scale.set_font_height(15,page,"Left")  
}


function current_page()
{
    local list_size = fe.list.size 
    local current_game = fe.list.index
    local total_pages = list_size/list_box.rows
    
    local over = current_game % list_box.rows
    local current_page = (current_game - over )/list_box.rows + 1
    return current_page + " / " + total_pages
}

if (config["rotate"]!="0")
{
    scale.set_font_height(20,page,"Left")
    scale.set_font_height(20,playtime,"Left")
}

if (config["dat_path"] != "" && config["overlay"]!="Air Attack")
{
    local dat_path=config["dat_path"]
    // local dat_path="/home/pi/.attract/mame2003-extras/history.dat" // path to history.dat file... even if set in plugin, still needs to be set here, or it needs to be grabbed from history.dat somehow
    local debug = false


    // by default, leave the history text off. Need to wait until the history.dat plugin is confirmed as enabled before using. check later in "ini" transition
    local info_text_window_height = scale.height(175)
    local info_text_window_width = scale.width(112)
    local info_text_container = fe.add_surface(info_text_window_width,  info_text_window_height)
    info_text_container.y=scale.y(215,"top",info_text_container,overlay,"top")
    info_text_container.x=scale.x(319,"left", info_text_container,overlay,"left")
    info_text_container.zorder=5
        
    local info_text_original_y =scale.y(10)
    local info_text_font_size = 10
    
    local info_text = info_text_container.add_text(
        "You must enable History.dat plugin to show history info in this tab", 
        scale.x(317), 
        scale.y(info_text_original_y), 
        scale.width(113), 
        scale.height(1200))
     
    if (config["rotate"]!="0")
    {
        info_text_font_size = 18
    }
    scale.set_font_height(info_text_font_size,info_text,"Left")

    
    info_text.align = Align.TopLeft
    info_text.word_wrap = true
    info_text.x = 0
    info_text.y= info_text_original_y
        
    // check to see if history.dat is available
    function init( ttype, var, ttime )
    {
        if ( ttype == Transition.StartLayout ){
            // this method does not seem to work in some of the other transitions
            if ( fe.plugin.rawin( "History.dat" )){
                info_text.msg = "[!get_hisinfo]"
            }
        }
        if (ttype= Transition.FromOldSelection){
            info_text.y=info_text_original_y
            if (scroll_speed == scroll_speed_without_delay)
            {
                scroll_speed=scroll_speed_with_delay
                next_time = scroll_speed + next_time
                return true 
            }
        }
        return false  
    } 
    fe.add_transition_callback( "init")

    /* ************************************  
    get_hisinfo

    returns history.dat info for current game

    @return text
    ************************************ */

    function get_hisinfo(index) 
    { 

        try {
            file(dat_path, "r" )
        }
        catch(e){
            return ""
        }


        local text = "" 

        local sys = split( fe.game_info( Info.System,index ), ";" ) 
        local rom = fe.game_info( Info.Name,index ) 
        local alt = fe.game_info( Info.AltRomname,index ) 
        local cloneof = fe.game_info( Info.CloneOf,index )  

        local lookup = get_history_offset( sys, rom, alt, cloneof ) 
        // we only go to the trouble of loading the entry if
        // it is not already currently loaded
        if ( lookup >= 0 )
        {
            text = get_history_entry( lookup, config ) 
            local index = text.find("- TECHNICAL -") 
            if (index >= 0)
            {
                local tempa = text.slice(0, index) 
                text = strip(tempa) 
            }
        } else {
            if ( lookup == -2 )
                text = "Index file not found. Try generating an index from the History.dat plug-in configuration menu." 
            else
                text = "No information available for:  " + rom 
        } 
        hist_msg_charcount = text.len() // this is new. set the total length of the message

        return text 
    }



    /* ************************************  
    historynav
    ticks callback

    automatically scrolls the history info after a few seconds. 

    for my future reference... this: 
    1. checks to see if the rough estimation of the height is taller than the screen
    2. checks the time since it was last checked so it's not checking too often
    3. I've set an initial check time of a few seconds plus a scroll speed so it doesn't start off scrolling immediately. As soon as that time's hit, it goes into the normal speed
    4. if the text's y position hasn't scrolled up to the position where we assume it will be when it's shown all of it's content, then continue scrolling
    5. otherwise if it's reached its end, then set the text almost off the bottom of the screen (behind stuff) and begin again. 
    @return false
    ************************************ */
    function historynav( tick_time )
    {       

        if (debug)
        {
            
            print("rough text length: " + abs(rough_text_length) + "\n")
            print("info_text_window_height" + info_text_window_height + "\n")
            print("info text position: " + info_text.y + "\n")
            print("screen height:  " + fe.layout.height + "\n\n")
            print("hist_msg_charcount " + hist_msg_charcount+ "\n\n")
            
        }

        /* I'm just gonna guess each line is somewhere between 50 and 100 characters on average. This is close enough to get 
        me a scroller with reset, but not good enough to get accurate positioning */ 
        local number_of_characters_assumed_per_line = 23    

        local font_width_to_height_ratio = 0.55 // based on rough cross section of font width to height ratios
        //local number_of_characters_assumed_per_line = info_text_window_width / (info_text_font_size * font_width_to_height_ratio) 
        local line_height = info_text_font_size

        //rough_text_length = (info_text_container.y + info_text_window_height) - hist_msg_charcount/number_of_characters_assumed_per_line * line_height  // get a negative value so it scrolls up
        rough_text_length = 0 - hist_msg_charcount/number_of_characters_assumed_per_line * line_height -20
            
            // calculation is: charcount/characters per line * font height = overally box height, roughly
        if (  abs(rough_text_length) > info_text_window_height)
        {
            // if (scroller_time_delay % 2 ==0)
            if (tick_time >= next_time)
            {
                scroll_speed = scroll_speed_without_delay // initial speed is set with a short pause before scrolling
                next_time = tick_time + scroll_speed 

                if (info_text.y > rough_text_length)
                {
                    
                    info_text.y= info_text.y - scale.y(1) // move up 1 px
                }  
                else
                {
                    info_text.y = info_text_container.y + info_text_window_height - 40 // setting base position... could set it somewhere else
                }
            }   
        }

        /*
        // this code uses inputs to move content up or down...
        if (fe.get_input_state("custom2")==true){
            if (info_text.y < 100){ info_text.y= info_text.y + 10} }
        if (fe.get_input_state("custom3")==true){
            if (info_text.y > rough_text_length){ info_text.y= info_text.y -10} }
        */ 
        return false
    }
    fe.add_ticks_callback("historynav");
}
else
{
        fav_image.y = scale.y(256,"top",fav_image,overlay,"top")
        fav_image.x = scale.x(331,"left",fav_image,overlay,"left")
        fav_image.width=scale.width(86)
        fav_image.height=scale.height(86)
}
        
if (config["overlay"]== "Air Attack")
{
    fav_image.y = scale.y(435,"top",fav_image,overlay,"top")
    fav_image.x = scale.x(402,"left",fav_image,overlay,"left")
    fav_image.width=scale.width(35)
    fav_image.height=scale.height(35)
}
    
