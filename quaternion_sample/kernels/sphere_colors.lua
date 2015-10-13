--- Colorful sphere effect.

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
local kernel = { language = "glsl", category = "filter", group = "sphere", name = "colors" }

-- Expose effect parameters using vertex data
kernel.vertexData = {
	{
		name = "nx",
		default = 0, 
		min = -1,
		max = 1,
		index = 0
	},

	{
		name = "ny",
		default = 0, 
		min = -1,
		max = 1,
		index = 1
	},

	{
		name = "nz",
		default = 1, 
		min = -1,
		max = 1,
		index = 2
	},
}

kernel.fragment = [[
	P_COLOR vec4 FragmentKernel (P_UV vec2 uv)
	{
		P_UV vec3 diff = vec3(2. * uv - 1., 0.);

		diff.z = sqrt(1. - dot(diff.xy, diff.xy));

		P_UV vec3 mid = (diff + CoronaVertexUserData.xyz);

		mid *= mid.yzx - mid.xyy * 1.3 + mid.zxy * .81;

		return CoronaColorScale(vec4(clamp(.5 * mid + .5, 0., 1.), 1.));
	}
]]

graphics.defineEffect(kernel)