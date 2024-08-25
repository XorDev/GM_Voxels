varying vec2 v_coord;

#define RES (u_map_res)

uniform vec4 u_map_res;

vec3 uv_to_block(vec2 uv)
{
    //Convert uv coordinates to pixel coordinates
    vec2 p = floor(uv * RES.xy * RES.zw);
    //Get the subcell x and y coordinates
    vec2 xy = mod(p, RES.xy);
    //Compute cell coordinates
    vec2 zw = mod((p-xy) / RES.xy, RES.zw);
    //Calculate the z value from xy cell position
    float z = dot(zw, vec2(1, RES.z));
    return vec3(xy,z);	
}
//Gyroid based cheap noise
float map(vec3 p)
{
    //Center z-axis of the map
    p.z -= 0.5*RES.z*RES.w;
    //Squish the z axis slightly
    p.z *= 1.5;
    //Irregular gyroid produces a decent noise pattern cheaply
    return dot(sin(p*0.131), cos(p.yzx*0.179)) - p.z*0.1;
}
//Tile the map by interpolating the edges
float map_tiled(vec3 p)
{
	//Sample the 4 corners of the map
	float m00 = map(p);
	float m10 = map(p - vec3(RES.x,0,0));
	float m01 = map(p - vec3(0,RES.y,0));
	float m11 = map(p - vec3(RES.xy,0));
	
	//Get the interpolation factor
	vec2 s = p.xy/RES.xy;
	//Quintic interpolation: https://x.com/XorDev/status/1649157830841098246
	s *= s * s*( 10. + s * (-15. + s*6.));
	
	//Horizontal interpolation
	vec2 h = mix(vec2(m00,m01), vec2(m10,m11), s.x);
	//Vertical interpolation
	return mix(h.x, h.y, s.y);	
}

void main()
{
	//Get 3D voxel coordinates
	vec3 v = uv_to_block(v_coord);
	//Sample tiled map function
	float m = map_tiled(v);
	
	//Return block index between 0 and 15
    gl_FragColor = vec4(clamp(m/6e1,0.0,15./255.));
}