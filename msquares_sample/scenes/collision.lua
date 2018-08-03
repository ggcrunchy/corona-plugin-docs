--- Scene that demonstrates boundary contours tessellation with the negative winding rule.

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

-- Modules --
local winding_bc = require("winding_bc")

-- Corona modules --
local composer = require("composer")

--
--
--

local Scene = composer.newScene()

-- Show --
function Scene:show (event)
	if event.phase == "did" then
		winding_bc.Show(self, "NEGATIVE")
	end
end

Scene:addEventListener("show")

--[[
	P_COLOR vec4 FragmentKernel (P_UV vec2 uv)
	{
		P_COLOR vec4 data = texture2D(CoronaSampler0, uv);
		P_UV vec3 n = vec3(2. * data.yz - 1., 0.);
		
		n.z = sqrt(max(1. - dot(n, n), 0.));

		P_UV vec3 ldir = vec3(ldir_xy * data.x, 3.75 * CoronaVertexUserData.w);

		ldir = normalize(ldir);

		P_UV float sim = max(dot(n, ldir), 0.);
		P_UV vec3 r = reflect(ldir, n);
		P_COLOR vec3 m = .35 * (vec3(.1 * IQ(r.xy), .3 * IQ(r.yz), .1 * IQ(r.xz) * data.x) + .5);
		P_COLOR vec4 color = vec4(mix(m, vec3(pow(1. - r.x, data.x)), .15) + vec3(pow(sim, 60.)), 1.);
//if (true) return vec4(data.yz,0.,1.);
		return clamp(color, 0., 1.) * smoothstep(.75, 1., data.a);
	}
]]

-- Hide --
function Scene:hide (event)
	if event.phase == "did" then
		winding_bc.Hide(self)
	end
end

Scene:addEventListener("hide")

return Scene