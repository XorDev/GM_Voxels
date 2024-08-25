#define RES (u_map_res)
#define STEPS 2e2
#define MAX 3e3

#define TEX_RES 8.0

uniform vec4 u_map_res;//w,h,dw,dh
uniform float u_time;
uniform vec3 u_res;//w,h,d
uniform vec4 u_tar;
uniform float u_rad;
uniform mat4 u_view;

uniform sampler2D u_tex;

varying vec2 v_coord;

vec2 block_to_uv(vec3 b)
{
	b.z = clamp(b.z, 0.0, RES.z*RES.w-1.0);
	vec2 sub_cell = fract(b.xy/RES.xy) / RES.zw;
	vec2 cell = fract(floor(b.z / vec2(1,RES.z)) / RES.zw);
	return sub_cell + cell;	
}

float map(vec3 p)
{
	return max(min(texture2D(gm_BaseTexture, block_to_uv(p)).r, (RES.z*RES.w-p.z)*0.1),(1.0-p.z)*.1);
}

struct hit
{
	vec3 pos;
	vec3 vox;
	vec3 nor;
	float steps;
	float depth;
};

hit voxel(vec3 p, vec3 d, float num)
{
    //Prevent division by 0 errors
    d += vec3(d.x==0.0, d.y==0.0, d.z==0.0) * 1e-5;
    
    //Sign direction for each axis
    vec3 sig = sign(d);
    //Step size for each axis
    vec3 stp = sig / d;
    
    //Voxel position
    vec3 vox = floor(p);
    //Initial step sizes to the next axis faces
    vec3 dep = ((vox-p + 0.5) * sig + 0.5) * stp;
    
    //Axis index
    vec3 axi;
    
    //Loop iterator
    float steps = 0.0;
    //Loop through voxels
    for(float i = 0.0; i<num; i++)
    {
        //Check map
        if (map(vox+0.5)>0.0) break;
        //Increment steps
        steps++;
        
        //Select the closest voxel face axis
        axi = dep.x<dep.z? 
             (dep.x<dep.y? vec3(1,0,0) : vec3(0,1,0) ):
             (dep.z<dep.y? vec3(0,0,1) : vec3(0,1,0) );
        
        //Step one voxel along this axis
        vox += sig * axi;
        //Set the length to the next voxel
        dep += stp * axi;
    }
	//Depth to intersection (the last step before a block)
	float depth = dot(dep - stp, axi);
	
	//Return hit data
	hit trace;
	trace.pos = p + depth*d;
	trace.vox = vox;
	trace.nor = -axi * sig;
	trace.steps = steps;
	trace.depth = depth;
	return trace;
}
//Experimental Ambient occlusion function
float block_ao(vec3 v, vec3 p, vec3 n)
{
	vec3 f = v+0.5+n;
	vec3 z = p-v-0.5;
	vec2 d = vec2(dot(z,n.yzx), dot(z,n.zxy));
	float s = 0.5;
	
	float ao = 1.0;
	
	//Check for adjacent blocks
	bool t1 = map(f-n.yzx)>0.0;
	bool t2 = map(f+n.yzx)>0.0;
	bool b1 = map(f-n.zxy)>0.0;
	bool b2 = map(f+n.zxy)>0.0;
	
	//Edge gradients
	if (t1) ao *= 1.0-s*(0.5 - d.x);
	if (t2) ao *= 1.0-s*(0.5 + d.x);
	if (b1) ao *= 1.0-s*(0.5 - d.y);
	if (b2) ao *= 1.0-s*(0.5 + d.y);
    
	//Corner gradients
	if (!t1 && !b2 && map(f-n.yzx+n.zxy)>0.0) ao *= 1.0-s*(0.5 - d.x)*(0.5 + d.y);
	if (!t2 && !b2 && map(f+n.yzx+n.zxy)>0.0) ao *= 1.0-s*(0.5 + d.x)*(0.5 + d.y);
	if (!t2 && !b1 && map(f+n.yzx-n.zxy)>0.0) ao *= 1.0-s*(0.5 + d.x)*(0.5 - d.y);
	if (!t1 && !b1 && map(f-n.yzx-n.zxy)>0.0) ao *= 1.0-s*(0.5 - d.x)*(0.5 - d.y);
	
	//Old algorithm
	/*
	for(float x = -1.0; x<=1.0; x++)
	for(float y = -1.0; y<=1.0; y++)
	{
		if (map(f+n.yzx*x+n.zxy*y)>0.0) 
			ao *= 1.0 -s*(1.0-0.5*x*x+d.x*x) * (1.0-0.5*y*y+d.y*y);	
	}
	*/
	return ao;
}

void main()
{
	//Ray direction
	vec2 cuv = v_coord - 0.5;
    vec3 dir = normalize(vec3(cuv, u_res.x) * u_res * mat3(u_view));
    
    //Don't let any component = 0.0
    dir += vec3(dir.x==0.0, dir.y==0.0, dir.z==0.0)/1e5;
	
	vec3 ddx_dir = dFdx(dir);
    vec3 ddy_dir = dFdy(dir);
    
    //Camera position
    vec3 cam_pos = -u_view[3].xyz * mat3(u_view);
    
	//Get hit data
	hit trace = voxel(cam_pos, dir, STEPS);
	vec3 vox = vec3(trace.vox);
	vec3 pos = vec3(trace.pos);
	vec3 nor = trace.nor;
	
	//Shadow pass
	vec3 sun = sqrt(vec3(0.1, 0.3, 0.6));
	hit shadow_hit = voxel(trace.pos + sun/1e3, sun, 1e2);
	float shadow = shadow_hit.steps<1e2? 0.4 : 1.0;
	float ao = block_ao(vox, pos, nor);
    
    //Block edge antialiasing
	//Konod: https://www.shadertoy.com/view/M3t3RX
    vec3 ddx = dot(dir, nor) / dot(dir + ddx_dir, nor) * (dir + ddx_dir) - dir;
    vec3 ddy = dot(dir, nor) / dot(dir + ddy_dir, nor) * (dir + ddy_dir) - dir;
    vec3 w = trace.depth * (abs(ddx) + abs(ddy));
	
	vec3 grid = fract(pos+nor*0.5);
	vec3 edge = 0.5-abs(grid-0.5);
	grid = clamp(edge/w, 0.0, 1.0);
	grid = grid*0.3+0.7;
	float grid_line = min(min(grid.x,grid.y),grid.z);
	
	//Get block id
	float index = texture2D(gm_BaseTexture, block_to_uv(vox+0.5)).r*255.0;
	//Texture
	vec3 t = fract(pos)*TEX_RES+0.5;
	vec3 f = floor(t);
	t = clamp(f + clamp((t-f-0.5)/w/TEX_RES,-0.5,0.5),0.5,TEX_RES-0.5)/TEX_RES;
	vec2 uv = (vec2(index,0) + fract(t.yz*nor.x+t.zx*nor.y+t.xy*nor.z))/vec2(16,1);
    vec3 tex = texture2D(u_tex, fract(uv)).rgb;
	tex *= grid_line;
	
	//Lighting and sky
    vec3 light = mix(vec3(0.1,0.2,0.3), vec3(1), (0.8+dot(nor,sun)*0.2) * shadow) * ao;
	float shade = trace.steps / STEPS;
	float scatter = 0.5-0.5*dot(dir,sun);
	vec3 horizon = 0.8/(1.+(dir.z+.3)*(dir.z+.3)/vec3(.15,.3,.8));
	vec3 sky = mix(horizon, vec3(1), .01/(.01+scatter/vec3(3,2,1)));
    light = mix(tex * light, sky, shade * shade);
	vec3 col = light;
	
	//Highlight blocks
	if (length(vox-u_tar.xyz)<u_rad)
	{
		col += (0.5-min(edge.x,min(edge.y,edge.z)))*(1.0 - col) * grid_line;
	}
	//Raycast
	if (length(cuv*u_res.xy)<1.0) col = (vox+nor*u_tar.w-floor(cam_pos)+127.0)/255.0;
    gl_FragColor = vec4(col,1);
}
