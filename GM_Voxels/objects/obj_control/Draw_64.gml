///@desc

var _ww = window_get_width();
var _wh = window_get_height();

gpu_set_blendenable(false);
if keyboard_check(ord("R")) surface_free(surf_map);

if !surface_exists(surf_map) 
{
	surf_map = surface_create(MAP_W,MAP_H,surface_r8unorm);
	
	surface_set_target(surf_map);
	draw_clear(0);
	shader_set(shd_gen);
	shader_set_uniform_f_array(u_gen_map_res, MAP_RES);
	draw_surface_stretched(application_surface,0,0,MAP_W,MAP_H);
	shader_reset();
	surface_reset_target();
}
if !surface_exists(surf_bac) surf_bac = surface_create(MAP_W,MAP_H,surface_r8unorm);

shader_set(shd_voxel);
shader_set_uniform_f_array(u_voxel_map_res, MAP_RES);
shader_set_uniform_f(u_voxel_time, get_timer()/1000000);
shader_set_uniform_matrix_array(u_voxel_view, mat_view);
shader_set_uniform_f(u_voxel_res, w, -h, 1/dtan(140/2));
shader_set_uniform_f(u_voxel_tar,tx,ty,tz, mouse_check_button(mb_right));
shader_set_uniform_f(u_voxel_rad,radius);
texture_set_stage(u_voxel_tex, t_tex);
draw_surface_stretched(surf_map,0,0,w,h);
shader_reset();


var _c = draw_getpixel(_ww/2,_wh/2);
tx = ((_c&255))-127+floor(px);
ty = ((_c>>8)&255)-127+floor(py);
tz = ((_c>>16)&255)-127+floor(pz);

place--;

if mouse_check_button_pressed(mb_right) type = irandom(14)+1;

var _dist = point_distance_3d(tx,ty,tz,px,py,pz)/100;
var _place = tap? mouse_check_button_pressed(mb_left) || mouse_check_button_pressed(mb_right) : 
				  mouse_check_button(mb_left) || mouse_check_button(mb_right);
_place *= place<=0;
if (mouse_check_button(mb_right)) _place *= _dist>0.03;

surface_set_target(surf_bac);
shader_set(shd_edit);
shader_set_uniform_f_array(u_edit_map_res, MAP_RES);
var _tx = modf(tx,MAP_RES[0]);
var _ty = modf(ty,MAP_RES[1]);
var _tz = modf(tz,MAP_RES[2]*MAP_RES[3]);
var _tt = mouse_check_button(mb_right) * type;
shader_set_uniform_f(u_edit_place,_tx,_ty,_tz,_tt);
shader_set_uniform_f(u_edit_radius, radius * _place);
draw_surface(surf_map,0,0);
shader_reset();
surface_reset_target();
	
surface_set_target(surf_map);
draw_surface(surf_bac,0,0);

surface_reset_target();
if (_place)
{
	var _sound =  mouse_check_button(mb_left) ? snd_break : snd_place;

	for(var i = 1; i<=radius; i*=1.1+random(.1))
	audio_play_sound(_sound,0,0,i/(1+_dist*5)/6,-random(radius-1)/i,exp(random(1)-_dist)/i);
	
	place = radius;
}

if keyboard_check(ord("1")) draw_surface(surf_map,0,0);


gpu_set_blendenable(true);