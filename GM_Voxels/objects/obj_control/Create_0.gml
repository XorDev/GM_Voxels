///@desc Initialize

//Screen res for scaling
w = window_get_width();
h = window_get_height();

//Lock mouse for first person view
window_mouse_set_locked(true);
window_set_cursor(cr_cross);

//Apply filterings
gpu_set_tex_filter(true);
gpu_set_tex_repeat(true);

MAP_RES = [256,256,8,8];
MAP_W = MAP_RES[0]*MAP_RES[2];
MAP_H = MAP_RES[1]*MAP_RES[3];

px = MAP_RES[0]/2;
py = MAP_RES[1]/2;
pz = MAP_RES[2]*MAP_RES[3];

dx = 0;
dy = 0;

tx = 0;
ty = 0; 
tz = 0;
type = 0;
place = 0;
tap = 0;
radius = 1;

surf_map = -1;
surf_bac = -1;

mat_view = matrix_build_identity();

u_gen_map_res = shader_get_uniform(shd_gen, "u_map_res");

u_edit_place = shader_get_uniform(shd_edit,"u_place");
u_edit_radius = shader_get_uniform(shd_edit, "u_radius");
u_edit_map_res = shader_get_uniform(shd_edit, "u_map_res");

u_voxel_time = shader_get_uniform(shd_voxel, "u_time");
u_voxel_view = shader_get_uniform(shd_voxel, "u_view");
u_voxel_res = shader_get_uniform(shd_voxel, "u_res");
u_voxel_tar = shader_get_uniform(shd_voxel, "u_tar");
u_voxel_rad = shader_get_uniform(shd_voxel, "u_rad");
u_voxel_map_res = shader_get_uniform(shd_voxel, "u_map_res");

u_voxel_tex = shader_get_sampler_index(shd_voxel,"u_tex");
t_tex = sprite_get_texture(spr_tex,0);
//gpu_set_tex_filter_ext(u_tex, false);

function modf(x,y)
{
	return x-floor(x/y)*y;	
}