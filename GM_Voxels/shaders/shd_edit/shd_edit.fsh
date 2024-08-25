varying vec2 v_coord;

#define RES (u_map_res)

uniform vec4 u_map_res;

uniform vec4 u_place;//x,y,z,type
uniform float u_radius;

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

vec2 block_to_uv(vec3 b)
{
    //Clamp the z to the map height range
    b.z = clamp(b.z, 0.0, RES.z * RES.w-1.0);
    //Compute subcell coordinates
    vec2 sub_cell = fract(b.xy / RES.xy) / RES.zw;
    //Compute cell coordinates
    vec2 cell = fract(floor(b.z / vec2(1,RES.z)) / RES.zw);
    return sub_cell + cell;	
}

void main()
{
	//Get 3D voxel coordinates
	vec3 v = uv_to_block(v_coord);
	//UV coordinates for current block, block below and above.
	vec2 uv_mi = v_coord;
	vec2 uv_do = block_to_uv(v+0.5-vec3(0,0,1));
	vec2 uv_up = block_to_uv(v+0.5+vec3(0,0,1));

	//Sample block index below
	float id_do = mod(texture2D(gm_BaseTexture, uv_do)*255.0,16.).r;
	if (v.z<1.0) id_do = 1.0; //Solid below map
	
	//Sample center block index
	float id_mi = mod(texture2D(gm_BaseTexture, uv_mi)*255.0,16.).r;
	
	//Sample block index above
	float id_up = mod(texture2D(gm_BaseTexture, uv_up)*255.0,16.).r;
	if (v.z>RES.z*RES.w-2.0) id_up = 0.0; //Empty above map
	
	//Apply powder physics to blocks
	float id = id_up>0.0 && id_mi<1.0? id_up : id_mi>0.0 && id_do<1.0? id_do: id_mi;
	
	//Distance to target block
	vec3 tar = v-u_place.xyz;
	//Tile x and y axes
	tar.xy = mod(tar.xy+RES.xy*0.5, RES.xy) - RES.xy*0.5;
	//Replace blocks within this radius
	if (length(tar)<u_radius) id = u_place.w;
	
	//Convert result back to 0 to 1 range
    gl_FragColor.r = (id+id*16.)/255.0;
}