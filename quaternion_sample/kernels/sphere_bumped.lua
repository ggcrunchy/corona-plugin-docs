--- Bumped lit sphere effect.

--
-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:
--
-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
-- CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
-- TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
-- SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--
-- [ MIT license: http://www.opensource.org/licenses/mit-license.php ]
--

-- Corona globals --
local graphics = graphics

-- Kernel --
local kernel = { language = "glsl", category = "filter", group = "sphere", name = "bumped" }

-- Expose effect parameters using vertex data
kernel.vertexData = {
	{
		name = "distance",
		default = 2, 
		min = 1,
		max = 5,
		index = 0
	},

	{
		name = "light_x",
		default = 1, 
		min = -1,
		max = 1,
		index = 1
	},

	{
		name = "light_y",
		default = 0, 
		min = -1,
		max = 1,
		index = 2
	},

	{
		name = "light_z",
		default = 0, 
		min = -1,
		max = 1,
		index = 3
	},
}

kernel.fragment = [[
	P_UV float PI = 4. * atan(1.);
	P_UV float TWO_PI = 8. * atan(1.);
	P_UV float PI_OVER_TWO = 2. * atan(1.);

	P_POSITION vec3 ComputeNormal (sampler2D s, P_UV vec2 uv, P_UV vec3 tcolor)
	{
		P_UV vec3 right = texture2D(s, uv + vec2(CoronaTexelSize.x, 0.)).rgb;
		P_UV vec3 above = texture2D(s, uv + vec2(0., CoronaTexelSize.y)).rgb;
		P_UV float rz = dot(right - tcolor, vec3(1.));
		P_UV float uz = dot(above - tcolor, vec3(1.));

		return normalize(vec3(-uz, -rz, 1.));
	}

	P_POSITION vec3 GetTangent (P_POSITION vec2 diff, P_POSITION float phi)
	{
		// In unit sphere, diff.y = sin(theta), sqrt(1 - sin(theta)^2) = cos(theta).
		return normalize(vec3(diff.yy * sin(vec2(phi + PI_OVER_TWO, -phi)), sqrt(1. - diff.y * diff.y)));
	}

	P_POSITION vec4 GetUV_ZPhi (P_POSITION vec2 diff)
	{
		P_POSITION float dist_sq = dot(diff, diff);
		P_POSITION float z = sqrt(1. - dist_sq);
		P_POSITION float phi = atan(z, diff.x);

		return vec4(.5 + phi / TWO_PI, .5 + asin(diff.y) / PI, z, phi);
	}

	P_POSITION vec3 GetWorldNormal_TS (P_UV vec3 bump, P_POSITION vec3 T, P_POSITION vec3 B, P_POSITION vec3 N)
	{
		return T * bump.x + B * bump.y + N * bump.z;
	}

	P_POSITION vec3 GetWorldNormal (P_UV vec3 bump, P_POSITION vec3 T, P_POSITION vec3 N)
	{
		return GetWorldNormal_TS(bump, T, cross(N, T), N);
	}

	P_COLOR vec4 FragmentKernel (P_UV vec2 uv)
	{
		P_UV vec2 diff = 2. * uv - 1.;
		P_UV vec4 uv_zp = GetUV_ZPhi(diff);

		if (uv_zp.s < 0.) return vec4(0.);

		P_COLOR vec4 tcolor = texture2D(CoronaSampler0, uv_zp.xy);
		P_COLOR vec3 bump = ComputeNormal(CoronaSampler0, uv_zp.xy, tcolor.rgb);
		P_POSITION vec3 N = vec3(diff, uv_zp.z);
		P_POSITION vec3 wn = GetWorldNormal(bump, GetTangent(diff, uv_zp.w), N);
		P_POSITION vec3 L = normalize(CoronaVertexUserData.yzw * CoronaVertexUserData.x - N); // x = distance, yzw = light position
		P_COLOR vec3 nl = min(.2 + tcolor.rgb * max(dot(wn, L), 0.), 1.);

		return CoronaColorScale(vec4(nl, 1.));
	}
]]

graphics.defineEffect(kernel)