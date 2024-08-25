///@desc

var _kb,_kf,_ks,_ku;
_kb = 0.2+0.8*keyboard_check(vk_shift);
_kf = (keyboard_check(ord("W")) - keyboard_check(ord("S")))*_kb;
_ks = (keyboard_check(ord("D")) - keyboard_check(ord("A")))*_kb;
_ku = (keyboard_check(ord("E")) - keyboard_check(ord("Q")))*_kb;

px += _kf*dcos(dx)*dcos(dy)-_ks*dsin(dx);
py += _kf*dsin(dx)*dcos(dy)+_ks*dcos(dx);
pz += _kf*dsin(dy)+_ku;

dx = (dx+window_mouse_get_delta_x()/10)%360;
dy = clamp(dy-window_mouse_get_delta_y()/10,-89,89);

mat_view = matrix_build_lookat(px,py,pz, px+dcos(dx)*dcos(dy),py+dsin(dx)*dcos(dy),pz+dsin(dy), 0,0,1);

if keyboard_check(vk_escape) game_end();

radius = clamp(radius+mouse_wheel_up()-mouse_wheel_down(),1,64);

if mouse_check_button_pressed(mb_middle) tap = !tap;