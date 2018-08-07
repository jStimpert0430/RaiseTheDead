pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
--raise the dead
--v0.0.3

--written by joshua stimpert https://secretbunta.itch.io/ -  https://github.com/jstimpert0430;

--project based upon --
--advanced micro platformer
--by @matthughson

--and

--advanced particle library
-- by viza https://www.lexaloffle.com/bbs/?tid=1920


--log
printh("\n\n-------\n-start-\n-------")

--config
--------------------------------
ticks = 0
--sfx
snd=
{
	jump=1,
	stomp=2,
	land =3,
	key =4,
	death =5,
	respawn=6,
	nextroom=7,
	start=8,
}

--music tracks
mus=
{

}

gameworld=
{
	versionnumber = "0.1",
	levelover = true,
	startpoint_x = 20,
	startpoint_y = 80,
	c_min_x = 0,
	c_min_y = 0,
	c_max_x = 64,
	c_max_y = 64,
	levelname = 'the crypt',
	levelkeyloc_x = 0,
	levelkeyloc_y = 0,
	currentlevel = 30,
	deaths = 0,
	phase = 2,
	minutes = 0,
	seconds = 0,
	pauseminutes = 0,
	pauseseconds = 0,
	textcolor = 7,
	flashingenabled = false,
	fallingthroughwood = false,
	starting = false,
}

levelcatalog={
}

--particle library
--------------------------------
function deleteallps()
	for ps in all(particle_systems) do
		del(particle_systems, ps)
	end
end

function sparks_demo()
	make_sparks_ps(rnd(107)+10,rnd(107)+10)
end

function make_sparks_ps(ex,ey)
	local ps = make_psystem(0.6,1, 2,3,0.5,0.5)
				--local newcolor = rnd(15)

	add(ps.emittimers,
		{
			timerfunc = emittimer_burst,
			params = { num = 1}
		}
	)
	add(ps.emitters,
		{
			emitfunc = emitter_point,
			params = { x = ex, y = ey, minstartvx = -1.5, maxstartvx = 1.5, minstartvy = -3, maxstartvy=-2 }
		}
	)
	add(ps.drawfuncs,
		{
			drawfunc = draw_ps_fillcirc,
			params = { colors = {2,2,2,13,13,13} }
		}
	)
	add(ps.affectors,
		{
			affectfunc = affect_force,
			params = { fx = 0, fy = 0.15 }
		}
	)
end

function make_sparks_small_ps(ex,ey)
	local ps = make_psystem(1,2, 1,2,1,3)

	add(ps.emittimers,
		{
			timerfunc = emittimer_burst,
			params = { num = 3}
		}
	)
	add(ps.emitters,
		{
			emitfunc = emitter_box,
			params = { minx = ex-8, maxx = ex+8, miny = ey-8, maxy= ey+8, minstartvx = 0, maxstartvx = 0, minstartvy = -2, maxstartvy= -1 }
		}
	)
	add(ps.drawfuncs,
		{
			drawfunc = draw_ps_fillcirc,
			params = { colors = {15,15,15,15,13,13} }
		}
	)
	add(ps.affectors,
		{
			affectfunc = affect_forcezone,
			params = { fx = -0.2, fy = 0.0, zoneminx = 32, zonemaxx = 127, zoneminy = 64, zonemaxy = 100 }
		}
	)
	add(ps.affectors,
		{
			affectfunc = affect_forcezone,
			params = { fx = 0.2, fy = 0.0, zoneminx = 0, zonemaxx = 64, zoneminy = 30, zonemaxy = 70 }
		}
	)
end


function make_smoke_ps(ex,ey)
	local ps = make_psystem(0.2,0.4, 0.5,1,1,2)

	add(ps.emittimers,
		{
			timerfunc = emittimer_burst,
			params = {num = 1}
		}
	)
	add(ps.emitters,
		{
			emitfunc = emitter_box,
			params = { minx = ex-4, maxx = ex+4, miny = ey, maxy= ey+2, minstartvx = 0, maxstartvx = 0, minstartvy = 0, maxstartvy=0 }
		}
	)
	add(ps.drawfuncs,
		{
			drawfunc = draw_ps_fillcirc,
			params = { colors = {7,7,13} }
		}
	)
	add(ps.affectors,
		{
			affectfunc = affect_force,
			params = { fx = 0.0, fy = -0.02 }
		}
	)
end

function make_starfield_ps()
	local ps = make_psystem(4,6, 1,2,0.5,0.5)
	ps.autoremove = false
	add(ps.emittimers,
		{
			timerfunc = emittimer_constant,
			params = {nextemittime = time(), speed = 0.01}
		}
	)
	add(ps.emitters,
		{
			emitfunc = emitter_box,
			params = { minx = 125, maxx = 127, miny = 0, maxy= 127, minstartvx = -2.0, maxstartvx = -0.5, minstartvy = 0, maxstartvy=0 }
		}
	)
	add(ps.drawfuncs,
		{
			drawfunc = draw_ps_pixel,
			params = { colors = {7,6,7,6,7,6,6,7,6,7,7,6,6,7} }
		}
	)
end

particle_systems = {}

function make_psystem(minlife, maxlife, minstartsize, maxstartsize, minendsize, maxendsize)
	local ps = {}
	-- global particle system params
	ps.autoremove = true

	ps.minlife = minlife
	ps.maxlife = maxlife

	ps.minstartsize = minstartsize
	ps.maxstartsize = maxstartsize
	ps.minendsize = minendsize
	ps.maxendsize = maxendsize

	-- container for the particles
	ps.particles = {}

	-- emittimers dictate when a particle should start
	-- they called every frame, and call emit_particle when they see fit
	-- they should return false if no longer need to be updated
	ps.emittimers = {}

	-- emitters must initialize p.x, p.y, p.vx, p.vy
	ps.emitters = {}

	-- every ps needs a drawfunc
	ps.drawfuncs = {}

	-- affectors affect the movement of the particles
	ps.affectors = {}

	add(particle_systems, ps)

	return ps
end

function update_psystems()
	local timenow = time()
	for ps in all(particle_systems) do
		update_ps(ps, timenow)
	end
end

function update_ps(ps, timenow)
	for et in all(ps.emittimers) do
		local keep = et.timerfunc(ps, et.params)
		if (keep==false) then
			del(ps.emittimers, et)
		end
	end

	for p in all(ps.particles) do
		p.phase = (timenow-p.starttime)/(p.deathtime-p.starttime)

		for a in all(ps.affectors) do
			a.affectfunc(p, a.params)
		end

		p.x += p.vx
		p.y += p.vy

		local dead = false
		if (p.x<0 or p.x>999 or p.y<0 or p.y>999) then
			dead = true
		end

		if (timenow>=p.deathtime) then
			dead = true
		end

		if (dead==true) then
			del(ps.particles, p)
		end
	end

	if (ps.autoremove==true and count(ps.particles)<=0) then
		del(particle_systems, ps)
	end
end

function draw_ps(ps, params)
	for df in all(ps.drawfuncs) do
		df.drawfunc(ps, df.params)
	end
end

function emittimer_burst(ps, params)
	for i=1,params.num do
		emit_particle(ps)
	end
	return false
end

function emittimer_constant(ps, params)
	if (params.nextemittime<=time()) then
		emit_particle(ps)
		params.nextemittime += params.speed
	end
	return true
end

function emit_particle(psystem)
	local p = {}

	local e = psystem.emitters[flr(rnd(#(psystem.emitters)))+1]
	e.emitfunc(p, e.params)

	p.phase = 0
	p.starttime = time()
	p.deathtime = time()+rnd(psystem.maxlife-psystem.minlife)+psystem.minlife

	p.startsize = rnd(psystem.maxstartsize-psystem.minstartsize)+psystem.minstartsize
	p.endsize = rnd(psystem.maxendsize-psystem.minendsize)+psystem.minendsize

	add(psystem.particles, p)
end

function emitter_point(p, params)
	p.x = params.x
	p.y = params.y

	p.vx = rnd(params.maxstartvx-params.minstartvx)+params.minstartvx
	p.vy = rnd(params.maxstartvy-params.minstartvy)+params.minstartvy
end

function emitter_box(p, params)
	p.x = rnd(params.maxx-params.minx)+params.minx
	p.y = rnd(params.maxy-params.miny)+params.miny

	p.vx = rnd(params.maxstartvx-params.minstartvx)+params.minstartvx
	p.vy = rnd(params.maxstartvy-params.minstartvy)+params.minstartvy
end

function affect_force(p, params)
	p.vx += params.fx
	p.vy += params.fy
end

function affect_forcezone(p, params)
	if (p.x>=params.zoneminx and p.x<=params.zonemaxx and p.y>=params.zoneminy and p.y<=params.zonemaxy) then
		p.vx += params.fx
		p.vy += params.fy
	end
end

function affect_stopzone(p, params)
	if (p.x>=params.zoneminx and p.x<=params.zonemaxx and p.y>=params.zoneminy and p.y<=params.zonemaxy) then
		p.vx = 0
		p.vy = 0
	end
end

function affect_bouncezone(p, params)
	if (p.x>=params.zoneminx and p.x<=params.zonemaxx and p.y>=params.zoneminy and p.y<=params.zonemaxy) then
		p.vx = -p.vx*params.damping
		p.vy = -p.vy*params.damping
	end
end

function affect_attract(p, params)
	if (abs(p.x-params.x)+abs(p.y-params.y)<params.mradius) then
		p.vx += (p.x-params.x)*params.strength
		p.vy += (p.y-params.y)*params.strength
	end
end

function affect_orbit(p, params)
	params.phase += params.speed
	p.x += sin(params.phase)*params.xstrength
	p.y += cos(params.phase)*params.ystrength
end

function draw_ps_fillcirc(ps, params)
	for p in all(ps.particles) do
		c = flr(p.phase*count(params.colors))+1
		r = (1-p.phase)*p.startsize+p.phase*p.endsize
		circfill(p.x,p.y,r,params.colors[c])
	end
end

function draw_ps_pixel(ps, params)
	for p in all(ps.particles) do
		c = flr(p.phase*count(params.colors))+1
		pset(p.x,p.y,params.colors[c])
	end
end

function draw_ps_streak(ps, params)
	for p in all(ps.particles) do
		c = flr(p.phase*count(params.colors))+1
		line(p.x,p.y,p.x-p.vx,p.y-p.vy,params.colors[c])
	end
end

function draw_ps_animspr(ps, params)
	params.currframe += params.speed
	if (params.currframe>count(params.frames)) then
		params.currframe = 1
	end
	for p in all(ps.particles) do
		pal(7,params.colors[flr(p.endsize)])
		spr(params.frames[flr(params.currframe+p.startsize)%count(params.frames)],p.x,p.y)
	end
	pal()
end

function draw_ps_agespr(ps, params)
	for p in all(ps.particles) do
		local f = flr(p.phase*count(params.frames))+1
		spr(params.frames[f],p.x,p.y)
	end
end

function draw_ps_rndspr(ps, params)
	for p in all(ps.particles) do
		pal(7,params.colors[flr(p.endsize)])
		spr(params.frames[flr(p.startsize)],p.x,p.y)
	end
	pal()
end


--collision interaction
----------------------------------------------
--point to box intersection.
function intersects_point_box(px,py,x,y,w,h)
	if flr(px)>=flr(x) and flr(px)<flr(x+w) and
				flr(py)>=flr(y) and flr(py)<flr(y+h) then
		return true
	else
		return false
	end
end

--box to box intersection
function intersects_box_box(
	x1,y1,
	w1,h1,
	x2,y2,
	w2,h2)

	local xd=x1-x2
	local xs=w1*0.5+w2*0.5
	if abs(xd)>=xs then return false end

	local yd=y1-y2
	local ys=h1*0.5+h2*0.5
	if abs(yd)>=ys then return false end

	return true
end

--check if pushing into side tile and resolve.
--requires self.dx,self.x,self.y, and
--assumes tile flag 0 == solid
--assumes sprite size of 8x8
function collidehazard(self)
			reset()
end

function collide_side(self)

	local offset=self.w/3
	for i=-(self.w/3),(self.w/3),2 do
	--if self.dx>0 then
		if fget(mget((self.x+(offset))/8,(self.y+i)/8),0) or fget(mget((self.x+(offset))/8,(self.y+i)/8),3) and not havekey then
			self.dx=0
			self.x=(flr(((self.x+(offset))/8))*8)-(offset)
			return true
		end
	--elseif self.dx<0 then
		if fget(mget((self.x-(offset))/8,(self.y+i)/8),0) or fget(mget((self.x-(offset))/8,(self.y+i)/8),3) and not havekey then
			self.dx=0
			self.x=(flr((self.x-(offset))/8)*8)+8+(offset)
			return true
		end
--	end
	end
	--didn't hit a solid tile.
	return false
end


function collide_nextlevel(self)

-- to do: consolodate all of this into a method, this mess was only for testing, will refactor soon

	local offset=self.w/3
	for i=-(self.w/3),(self.w/3),2 do
	--if self.dx>0 then
		if fget(mget((self.x+(offset))/8,(self.y+i)/8),7) and havekey then
			gameworld.levelover = true
			sfx(snd.nextroom)
			if gameworld.c_min_y < 384 then
			gameworld.startpoint_y = gameworld.startpoint_y + 128
			gameworld.c_min_y = gameworld.c_min_y + 128
			gameworld.c_max_y = gameworld.c_max_y + 128
			gameworld.currentlevel = gameworld.currentlevel - 1
			reset()
			gameworld.phase = 5
		else
			gameworld.startpoint_y = 80
			gameworld.startpoint_x = gameworld.startpoint_x + 128
			gameworld.c_min_y = 0
			gameworld.c_max_y = 64
			gameworld.currentlevel = gameworld.currentlevel	- 1
			gameworld.c_min_x = gameworld.c_min_x + 128
			gameworld.c_max_x = gameworld.c_max_x + 128
			reset()
			gameworld.phase = 5
		end
			return true
		end
	--elseif self.dx<0 then
		if fget(mget((self.x-(offset))/8,(self.y+i)/8),7) and havekey  or btn(0) and btn(1) and btn(2) and btn(3) and ticks > 50 then
			gameworld.levelover = true
			sfx(snd.nextroom)
			if gameworld.c_min_y < 384 then
			gameworld.startpoint_y = gameworld.startpoint_y + 128
			--gameworld.c_min_y = gameworld.c_min_y + 128
			gameworld.c_min_y = gameworld.c_min_y + 128
			gameworld.c_max_y = gameworld.c_max_y + 128
			gameworld.currentlevel = gameworld.currentlevel - 1
			reset()
			gameworld.phase = 5
		else
			gameworld.startpoint_y = 80
			gameworld.startpoint_x = gameworld.startpoint_x + 128
			gameworld.c_min_y = 0
						gameworld.c_max_y = 64
			gameworld.currentlevel = gameworld.currentlevel	- 1
			gameworld.c_min_x = gameworld.c_min_x + 128
						gameworld.c_max_x = gameworld.c_max_x + 128
			reset()
			gameworld.phase = 5
		end
			return true
		end
--	end
	end
	--didn't hit a solid tile.
	return false
end

--check if pushing into floor tile and resolve.
--requires self.dx,self.x,self.y,self.grounded,self.airtime and
--assumes tile flag 0 or 1 == solid
function collide_floor(self)
	--only check for ground when falling.
	if self.dy<0 then
		return false
	end
	local landed=false
	--check for collision at multiple points along the bottom
	--of the sprite: left, center, and right.
	for i=-(self.w/3),(self.w/3),2 do
		local tile=mget((self.x+i)/8,(self.y+(self.h/2))/8)
		if fget(tile,0) or (fget(tile,1) and self.dy>=0 and not self.fallingthroughwood) or  fget(tile, 3) and not havekey then
			--if(self.dy == 2) then cam:shake(15,2) end --if fall speed at max, shake cam
			self.dy=0
			self.y=(flr((self.y+(self.h/2))/8)*8)-(self.h/2)
			self.grounded=true
			self.airtime=0
			lasthitwashead = false
			self.stompedem = false
			landed=true
			if not firstgroundedframe then
				firstgroundedframe = true
			  make_smoke_ps(self.x + 4,self.y + 3)
				make_smoke_ps(self.x - 4,self.y + 3)
				sfx(snd.land)
			end
		end
	end
	return landed
end


function collide_enemy_head(self)
	if self.dy<0 then
		return false
	end
	local stomped = false

	for i=- (self.w/3), (self.w/3), 2 do
		local tile=mget((self.x+i)/8,(self.y+(self.h/2))/8)
		if fget(tile,2) then
			self.grounded  = true
			self.airtime=0
			self.jump_hold_time = 0
		 	self.stompedem = true
			stomped = true
			cam:shake(7,2)
			make_sparks_ps(self.x, self.y + 8)
			make_smoke_ps(self.x,self.y + 3)
		end
	end
	return stomped
end


function collide_death(self)
	--only check for death when falling.
	--check for collision at multiple points along the bottom
	--of the sprite: left, center, and right.
		local tile=mget((self.x)/8,(self.y+(self.h/4))/8)
		if fget(tile,4) or self.y > gameworld.c_min_y + 123 and gameworld.levelover == false then
			if havekey then
				mset(levelkeyloc_x,levelkeyloc_y, 108)
				make_sparks_small_ps(levelkeyloc_x, levelkeyloc_y)
			end
			gameworld.deaths = gameworld.deaths + 1
			make_sparks_ps(self.x, self.y)
			make_sparks_ps(self.x, self.y)
			make_sparks_ps(self.x, self.y)
			make_sparks_ps(self.x, self.y)
			make_smoke_ps(self.x,self.y + 0)
		  make_smoke_ps(self.x,self.y + 3)
			make_smoke_ps(self.x,self.y + -3)
			make_smoke_ps(self.x,self.y + -6)
			sfx(snd.death)
			gameworld.phase = 3
			--reset()
		end
end


function collide_death_roof(self)
	--only check for ground when falling.
	if self.dy<0 then
		return false
	end
	local landed=false
	--check for collision at multiple points along the bottom
	--of the sprite: left, center, and right.
		local tile=mget((self.x)/8,(self.y-(self.h/2))/8)
		if fget(tile,4) or self.y > gameworld.c_min_y + 123 and gameworld.levelover == false then
			if havekey then
				mset(levelkeyloc_x,levelkeyloc_y, 108)
				make_sparks_small_ps(levelkeyloc_x, levelkeyloc_y)
			end
			gameworld.deaths = gameworld.deaths + 1
			make_sparks_ps(self.x, self.y)
			make_sparks_ps(self.x, self.y)
			make_sparks_ps(self.x, self.y)
			make_sparks_ps(self.x, self.y)
			make_smoke_ps(self.x,self.y + 0)
			make_smoke_ps(self.x,self.y + 3)
			make_smoke_ps(self.x,self.y + -3)
			make_smoke_ps(self.x,self.y + -6)
			sfx(snd.death)
			gameworld.phase = 3
			--reset()
		end
	return landed
end


function collide_key(self)
	--only check for ground when falling.
	if self.dy<0 then
		return false
	end
	local landed=false
	--check for collision at multiple points along the bottom
	--of the sprite: left, center, and right.
	for i=-(self.w/3),(self.w/3),2 do
		local tile=mget((self.x+i)/8,(self.y+(self.h/2))/8)
		if fget(tile,6) then
		mset((self.x+i)/8,(self.y+(self.h/2))/8, 0)
		levelkeyloc_x = (self.x+i)/8
		levelkeyloc_y = (self.y+(self.h/2))/8
		havekey = true
		sfx(snd.key)
		make_sparks_small_ps(self.x, self.y)
		end
	end
	return landed
end

function collide_key_side(self)

	local offset=self.w/3
	--if self.dx>0 then
		if fget(mget((self.x+(offset))/8,(self.y)/8),6) then
			mset((self.x+(offset))/8,(self.y)/8)
			levelkeyloc_x = (self.x+(offset))/8
			levelkeyloc_y = (self.y)/8
			havekey = true
			sfx(snd.key)
			make_sparks_small_ps(self.x, self.y)
			return true
		end
	--elseif self.dx<0 then
		if fget(mget((self.x-(offset))/8,(self.y)/8),6) then
			mset((self.x-(offset))/8,(self.y)/8)
			levelkeyloc_x = (self.x-(offset))/8
			levelkeyloc_y = (self.y)/8
			havekey = true
			sfx(snd.key)
			make_sparks_small_ps(self.x, self.y)
			return true
		end
--	end
	--didn't hit a solid tile.
	return true
end
--check if pushing into roof tile and resolve.
--requires self.dy,self.x,self.y, and
--assumes tile flag 0 == solid
function collide_roof(self)
	--check for collision at multiple points along the top
	--of the sprite: left, center, and right.
	for i=-(self.w/3),(self.w/3),2 do
		if fget(mget((self.x+i)/8,(self.y-(self.h/2))/8),0) or  fget(mget((self.x+i)/8,(self.y-(self.h/2))/8),3) and not havekey then
			self.dy=0
			self.y=flr((self.y-(self.h/2))/8)*8+8+(self.h/2)
			self.jump_hold_time=0
		end
	end
end

--make 2d vector
function m_vec(x,y)
	local v=
	{
		x=x,
		y=y,

  --get the length of the vector
		get_length=function(self)
			return sqrt(self.x^2+self.y^2)
		end,

  --get the normal of the vector
		get_norm=function(self)
			local l = self:get_length()
			return m_vec(self.x / l, self.y / l),l;
		end,
	}
	return v
end

--square root.
function sqr(a) return a*a end

--round to the nearest whole number.
function round(a) return flr(a+0.5) end


--utils
--------------------------------

--print string with outline.
function printo(str,startx,
															 starty,col,
															 col_bg)
	print(str,startx+1,starty,col_bg)
	print(str,startx-1,starty,col_bg)
	print(str,startx,starty+1,col_bg)
	print(str,startx,starty-1,col_bg)
	print(str,startx+1,starty-1,col_bg)
	print(str,startx-1,starty-1,col_bg)
	print(str,startx-1,starty+1,col_bg)
	print(str,startx+1,starty+1,col_bg)
	print(str,startx,starty,col)
end

--print string centered with
--outline.
function printc(
	str,x,y,
	col,col_bg,
	special_chars)

	local len=(#str*4)+(special_chars*3)
	local startx=x-(len/2)
	local starty=y-2
	printo(str,startx,starty,col,col_bg)
end

--objects
--------------------------------

--make the player
function m_player(x,y)

	--todo: refactor with m_vec.
	local p=
	{
		x=x,
		y=y,

		dx=0,
		dy=0,

		w=8,
		h=8,

		max_dx=1,--max x speed
		max_dy=3.0,--max y speed

		jump_speed=-1.25,--jump veloclity
		acc=0.085,--acceleration
		dcc=0.8,--decceleration
		air_dcc=0.95,--air decceleration
		grav=0.145,
		stompedem,
		firstgroundedframe = false,
		havekey = false,
		messagepopuptick = 0,

		--helper for more complex
		--button press tracking.
		--todo: generalize button index.
		jump_button=
		{
			update=function(self)
				--start with assumption
				--that not a new press.
				self.is_pressed=false
				if btn(4) or self.stompedem then
					if not self.is_down then
						self.is_pressed=true
					--	self.stompedem = false
					end
					self.is_down=true
					self.ticks_down+=1
				else
					self.is_down=false
					self.is_pressed=false
					self.ticks_down=0
				end
			end,
			--state
			is_pressed=false,--pressed this frame
			is_down=false,--currently down
			ticks_down=0,--how long down
		},

		jump_hold_time=0,--how long jump is held
		min_jump_press=5,--min time jump can be held
		max_jump_press=15,--max time jump can be held

		jump_btn_released=true,--can we jump again?
		grounded=false,--on ground
		hithazard = false,
		--stompedem = false,


		airtime=0,--time since grounded

		--animation definitions.
		--use with set_anim()
		anims=
		{
			["stand"]=
			{
				ticks=1,--how long is each frame shown.
				frames={2},--what frames are shown.
			},
			["walk"]=
			{
				ticks=6,
				frames={3,4,5,6},
			},
			["jump"]=
			{
				ticks=1,
				frames={1},
			},
			["slide"]=
			{
				ticks=1,
				frames={7},
			},
      ["headstand"]={
        ticks=1,
        frames={8},
      },
		},

		curanim="walk",--currently playing animation
		curframe=1,--curent frame of animation.
		animtick=0,--ticks until next frame should show.
		flipx=false,--show sprite be flipped.

		--request new animation to play.
		set_anim=function(self,anim)
			if(anim==self.curanim)return--early out.
			local a=self.anims[anim]
			self.animtick=a.ticks--ticks count down.
			self.curanim=anim
			self.curframe=1
		end,

		--call once per tick.
		update=function(self)
			local bl=btn(0) --left
			local br=btn(1) --right

			--move left/right
			if bl==true then
				self.dx-=self.acc
				br=false--handle double press
			elseif br==true then
				self.dx+=self.acc
			else
				if self.grounded then
					self.dx*=self.dcc
				else
					self.dx*=self.air_dcc
				end
			end

			--limit walk speed
			self.dx=mid(-self.max_dx,self.dx,self.max_dx)

			--move in x
			self.x+=self.dx

			--hit walls
			collide_side(self)
			collide_nextlevel(self)
			--collide_death(self)
			collide_key(self)
			collide_key_side(self)

			--jump buttons
			self.jump_button:update()

			--jump is complex.
			--we allow jump if:
			--	on ground
			--	recently on ground
			--	pressed btn right before landing
			--also, jump velocity is
			--not instant. it applies over
			--multiple frames.
			if self.jump_button.is_down or self.stompedem then
				--is player on ground recently.
				--allow for jump right after
				--walking off ledge.
				local on_ground=(self.grounded or self.airtime<5)
				--was btn presses recently?
				--allow for pressing right before
				--hitting ground.
				local new_jump_btn=self.jump_button.ticks_down<10
				--is player continuing a jump
				--or starting a new one?
				if self.jump_hold_time>0 or (on_ground and new_jump_btn) or self.stompedem then
					if self.jump_hold_time==0 then if not self.stompedem then sfx(snd.jump) else sfx(snd.stomp) end end--new jump snd
					self.stompedem = false
					self.jump_hold_time+=1
					--keep applying jump velocity
					--until max jump time.
					if self.jump_hold_time<self.max_jump_press then
						self.dy=self.jump_speed--keep going up while held
					end
				end
			else
				self.jump_hold_time=0
			end

			--move in y
			self.dy+=self.grav
			self.dy=mid(-self.max_dy,self.dy,self.max_dy)
			self.y+=self.dy

			--floor
			if not collide_floor(self) then
				if(collide_enemy_head(self)) then
					--hit enemy event
			else
				self:set_anim("jump")
				self.grounded=false
				self.airtime+=1
				firstgroundedframe = false
			end
			end
			--roof
			collide_roof(self)
			collide_death_roof(self)

			--handle playing correct animation when
			--on the ground.
			if self.grounded then
				if br then
					if self.dx<0 then
						--pressing right but still moving left.
						self:set_anim("slide")
					else
						self:set_anim("walk")
					end
				elseif bl then
					if self.dx>0 then
						--pressing left but still moving right.
						self:set_anim("slide")
					else
						self:set_anim("walk")
					end
				else
					self:set_anim("stand")
				end
			end

			--flip
			if br then
				self.flipx=false
			elseif bl then
				self.flipx=true
			end

			--anim tick
			self.animtick-=1
			if self.animtick<=0 then
				self.curframe+=1
				local a=self.anims[self.curanim]
				self.animtick=a.ticks--reset timer
				if self.curframe>#a.frames then
					self.curframe=1--loop
				end
			end

		end,

		--draw the player
		draw=function(self)
			if gameworld.phase ==2 then
			local a=self.anims[self.curanim]
			local frame=a.frames[self.curframe]
			spr(frame,
				self.x-(self.w/2),
				self.y-(self.h/2),
				self.w/8,self.h/8,
				self.flipx,
				false)
        spr(8, self.x - 4, self.y - 8, self.w/8, self.h/8, self.flipx, false)
				if havekey then spr(108, self.x-4, self.y -13)  end -- spr(114, self.x-4, self.y -18)  printc('key ok!', self.x, self.y - 10, 7, 0, 0)
			end
		end,
	}

	return p
end

--make the camera. --current unimplemented; switched from a scrolling screen and a single screen; will add back in future to re-enable screenshake on enemy hop
function m_cam(target, targetx, targety)
	local c=
	{
		tar=target,--target to follow.
		pos=m_vec(targetx,targety),

		--how far from center of screen target must
		--be before camera starts following.
		--allows for movement in center without camera
		--constantly moving.
		pull_threshold=16,

		--min and max positions of camera.
		--the edges of the level.
		pos_min=m_vec(targetx, targety),
		pos_max=m_vec(targetx,targety),

		shake_remaining=0,
		shake_force=0,

		update=function(self)

			self.shake_remaining=max(0,self.shake_remaining-1)

			--follow target outside of
			--pull range.
			if self:pull_max_x()<self.tar.x then
				self.pos.x+=min(self.tar.x-self:pull_max_x(),4)
			end
			if self:pull_min_x()>self.tar.x then
				self.pos.x+=min((self.tar.x-self:pull_min_x()),4)
			end
			if self:pull_max_y()<self.tar.y then
				self.pos.y+=min(self.tar.y-self:pull_max_y(),4)
			end
			if self:pull_min_y()>self.tar.y then
				self.pos.y+=min((self.tar.y-self:pull_min_y()),4)
			end

			--lock to edge
			if(self.pos.x<self.pos_min.x)self.pos.x=self.pos_min.x
			if(self.pos.x>self.pos_max.x)self.pos.x=self.pos_max.x
			if(self.pos.y<self.pos_min.y)self.pos.y=self.pos_min.y
			if(self.pos.y>self.pos_max.y)self.pos.y=self.pos_max.y
		end,

		cam_pos=function(self)
			--calculate camera shake.
			local shk=m_vec(0,0)
			if self.shake_remaining>0 then
				shk.x=rnd(self.shake_force)-(self.shake_force/2)
				shk.y=rnd(self.shake_force)-(self.shake_force/2)
			end
			return self.pos.x-64+shk.x,self.pos.y-64+shk.y
		end,

		pull_max_x=function(self)
			return self.pos.x+self.pull_threshold
		end,

		pull_min_x=function(self)
			return self.pos.x-self.pull_threshold
		end,

		pull_max_y=function(self)
			return self.pos.y+self.pull_threshold
		end,

		pull_min_y=function(self)
			return self.pos.y-self.pull_threshold
		end,

		shake=function(self,ticks,force)
			self.shake_remaining=ticks
			self.shake_force=force
		end
	}

	return c
end

--timers
----------------------------------
-- start timers code

local timers = {}
local last_time = nil

function init_timers ()
  last_time = time()
end

function add_timer (name,
    length, step_fn, end_fn,
    start_paused)
  local timer = {
    length=length,
    elapsed=0,
    active=not start_paused,
    step_fn=step_fn,
    end_fn=end_fn
  }
  timers[name] = timer
  return timer
end

function update_timers ()
  local t = time()
  local dt = t - last_time
  last_time = t
  for name,timer in pairs(timers) do
    if timer.active then
      timer.elapsed += dt
      local elapsed = timer.elapsed
      local length = timer.length
      if elapsed < length then
        if timer.step_fn then
          timer.step_fn(dt,elapsed,length)
        end
      else
        if timer.end_fn then
          timer.end_fn(dt,elapsed,length)
        end
        timer.active = false
      end
    end
  end
end

function pause_timer (name)
  local timer = timers[name]
  if (timer) timer.active = false
end

function resume_timer (name)
  local timer = timers[name]
  if (timer) timer.active = true
end

function restart_timer (name, start_paused)
  local timer = timers[name]
  if (not timer) return
  timer.elapsed = 0
  timer.active = not start_paused
end


--game flow
--------------------------------

--reset the game to its initial
--state. use this instead of
--_init()
function reset()
	ticks=0
			fallingticks = 0
			startticks = 0
	p1=m_player(gameworld.startpoint_x, gameworld.startpoint_y)
	p1:set_anim("walk")
			cam=m_cam(p1, gameworld.c_min_x + 64, gameworld.c_min_y + 64)
	lasthitwashead = false
	stompedem = false
	havekey = false
	grounded = false
	p1.jump_hold_time = 20
	deadticks = 0
	gameworld.textcolor = 7
	--gameworld.phase = 2
	--sfx(snd.respawn)
end

--p8 functions
--------------------------------

function _init()

	init_timers()

	reset()
		--cam=m_cam(p1, gameworld.c_min_x + 64, gameworld.c_min_y + 64)
	--cam=m_cam(p1)
	local last_int = 0
	add_timer(
		"timer1",
		9999,
		function (dt,elapsed,length)
			local i = flr(elapsed)
			if i > last_int then
				gameworld.minutes = flr((i / 2) /  60)
				gameworld.seconds = flr(i / 2) - (gameworld.minutes * 60)
				if gameworld.phase == 3 and not active or gameworld.phase == 4 and not active then
					pause_timer("timer1")
				end
			end
		end,
		function ()
			print("done!")
			sfx(10)
		end
		)
		gameworld.phase = 1
		pause_timer("timer1")
end

function _update60()
		ticks+=1
			cam:update()
	if gameworld.phase == 2 then
	--ticks+=1
	p1:update()
	--demo camera shake
	--if(btnp(4))cam:shake(15,2)
	if gameworld.currentlevel < 21 then
		gameworld.phase = 4
	end
end

if gameworld.phase == 1 and btnp(4) then
	sfx(snd.start)
	gameworld.starting = true
end

if gameworld.phase ==1 and gameworld.starting then
	startticks +=1
	if gameworld.phase == 1 and startticks > 50 then
		  startticks = 0
			gameworld.phase = 5
			--resume_timer("timer1")
		end
end

if gameworld.phase == 5 and gameworld.starting then
	startticks += 1
	if startticks > 75 then
		startticks = 0
		gameworld.phase = 2
		resume_timer("timer1")
		gameworld.levelover = false
	end
end



if gameworld.phase ==3 then
	deadticks += 1
	if btnp(4) and deadticks > 60 then
			gameworld.phase =5
			reset()
			make_smoke_ps(p1.x,p1.y + 0)
			make_smoke_ps(p1.x,p1.y + 3)
			make_smoke_ps(p1.x,p1.y + -3)
			make_smoke_ps(p1.x,p1.y + -6)
			make_smoke_ps(p1.x + 3,p1.y + 0)
			make_smoke_ps(p1.x - 3,p1.y + 0)
						sfx(snd.nextroom)
	end
end
	update_psystems()
	update_timers()
	if p1.grounded and btn(3) then
		p1.fallingthroughwood = true
	end
	if p1.fallingthroughwood then
		fallingticks+=1
		if(fallingticks > 10)then
			p1.fallingthroughwood = false
			fallingticks = 0
		end
	end
end

function _draw()

	cls(0)

	camera(cam:cam_pos())

	map(0,0,0,0,128,128)

	p1:draw()
  --spr(8, local.x, local.y -5)--
	for ps in all(particle_systems) do
		draw_ps(ps)
	end

	if gameworld.phase == 1 then
		--gameworld.textcolor = 13
		rectfill(gameworld.c_min_x, gameworld.c_min_y, gameworld.c_min_x + 128, gameworld.c_min_y + 128, 0)
		rectfill(gameworld.c_min_x, gameworld.c_min_y + 30, gameworld.c_min_x + 128, gameworld.c_min_y + 100, 2)
		rectfill(gameworld.c_min_x, gameworld.c_min_y + 30, gameworld.c_min_x + 128, gameworld.c_min_y + 85, 1)
				rect(gameworld.c_min_x - 10, gameworld.c_min_y + 30, gameworld.c_min_x + 128, gameworld.c_min_y + 100, 0)
								rect(gameworld.c_min_x - 10, gameworld.c_min_y + 34, gameworld.c_min_x + 128, gameworld.c_min_y + 35, 13)
															--rect(gameworld.c_min_x - 10, gameworld.c_min_y + 84, gameworld.c_min_x + 128, gameworld.c_min_y + 85, 13)
		printc("raise the dead v." .. gameworld.versionnumber, gameworld.c_min_x + 64, gameworld.c_min_y +35, 7, 0, 0)
		printc("by joshua stimpert", gameworld.c_min_x + 64, gameworld.c_min_y +65,7 , 0, 0)
		printc("(@tofushopdev)", gameworld.c_min_x + 64, gameworld.c_min_y +75, 7, 0, 0)
		printc(" \143 game is best played\n on a controller", gameworld.c_min_x+80, gameworld.c_min_y+115, 13, 0, 0)

		--printc("raise the dead v." .. gameworld.versionnumber, gameworld.c_min_x + 64, gameworld.c_min_y +35, 7, 0, 0)
		if ticks % 32 == 0 or gameworld.starting then
			flashingenabled = true
		end
		if ticks % 64 == 0 and not gameworld.starting then
			flashingenabled = false

		end

		if flashingenabled then
					if gameworld.starting then
					printc("start!", gameworld.c_min_x + 64, gameworld.c_min_y +93, 8, 0, 0)
					else
					printc("press \142 to start", gameworld.c_min_x + 64, gameworld.c_min_y +93, 7, 0, 0)

				end
				end
		spr(8, gameworld.c_min_x + 60, gameworld.c_min_y + 40)
	end

	if gameworld.phase == 5 then
		rectfill(gameworld.c_min_x, gameworld.c_min_y + 60, gameworld.c_min_x + 128, gameworld.c_min_y + 85, 1)
		rectfill(gameworld.c_min_x, gameworld.c_min_y + 60, gameworld.c_min_x + 128, gameworld.c_min_y + 60, 0)
				rectfill(gameworld.c_min_x, gameworld.c_min_y + 85, gameworld.c_min_x + 128, gameworld.c_min_y + 85, 0)
		--rect(gameworld.c_min_x - 10, gameworld.c_min_y + 65, gameworld.c_min_x + 128, gameworld.c_min_y + 35, 13)
		--rect(gameworld.c_min_x - 10, gameworld.c_min_y + 64, gameworld.c_min_x + 128, gameworld.c_min_y + 35, 13)
		if gameworld.currentlevel == 30 then
		printc("floor: " .. gameworld.currentlevel, gameworld.c_min_x + 64, gameworld.c_min_y +65, 7, 0, 0)
	else
				printc("floor: " .. gameworld.currentlevel, gameworld.c_min_x + 64, gameworld.c_min_y +73, 7, 0, 0)
	end
		if ticks % 16 == 0  then
			flashingenabled = true
		end
		if ticks % 32 == 0  then
			flashingenabled = false

		end
		if flashingenabled and gameworld.currentlevel == 30 then
				printc("raise the dead!", gameworld.c_min_x + 64, gameworld.c_min_y +75, 8, 0, 0)
			else if gameworld.currentlevel == 30 then
				printc("raise the dead!", gameworld.c_min_x + 64, gameworld.c_min_y +75, 7, 0, 0)
			end
			end

	end



	if gameworld.phase == 3 then
		gameworld.textcolor = 13
		rectfill(gameworld.c_min_x, gameworld.c_min_y + 60, gameworld.c_min_x + 128, gameworld.c_min_y + 80, 2)
		printc("\140:" .. gameworld.deaths, gameworld.c_min_x + 64, gameworld.c_min_y +65, 7, 0, 0)
		printc(" r.i.p. in peace", gameworld.c_min_x + 64, gameworld.c_min_y + 75, 7, 0, 0)
		if deadticks > 60 then
			printc("press \142 to respawn", gameworld.c_min_x + 64, gameworld.c_min_y +85, 7, 0, 0)
		end
	end

	if gameworld.phase == 4 then
			gameworld.textcolor = 13
			--rectfill(gameworld.c_min_x, gameworld.c_min_y + 0, gameworld.c_min_x + 128, gameworld.c_min_y + 128, 0)
			rectfill(gameworld.c_min_x, gameworld.c_min_y + 30, gameworld.c_min_x + 128, gameworld.c_min_y + 100, 2)
			printc("raise the dead v." .. gameworld.versionnumber, gameworld.c_min_x + 64, gameworld.c_min_y +10, 7, 0, 0)
			spr(8, gameworld.c_min_x + 64, gameworld.c_min_y + 15)
			printc("deaths:".. gameworld.deaths .. "  \147:"..gameworld.minutes .."'".. gameworld.seconds, gameworld.c_min_x + 64, gameworld.c_min_y +105, 7, 0, 0)
			printc("congratuations! you win!", gameworld.c_min_x + 64, gameworld.c_min_y +35, 7, 0, 0)
			printc("unfortunetly, the path to the", gameworld.c_min_x + 64, gameworld.c_min_y +45, 7, 0, 0)
			printc("exit isn't completed yet.", gameworld.c_min_x + 64, gameworld.c_min_y +55, 7, 0, 0)
			printc("i'm constantly updating though,", gameworld.c_min_x + 64, gameworld.c_min_y +75, 7, 0, 0)
			printc("so please check back soon!", gameworld.c_min_x + 64, gameworld.c_min_y +85, 7, 0, 0)
			printc("thanks for playing \140", gameworld.c_min_x + 64, gameworld.c_min_y +95, 7, 0, 0)

	end

	--hud
	camera(0,0)
	if gameworld.phase == 2 or gameworld.phase == 3 or gameworld.phase == 5 then
	if gameworld.seconds < 10 then
						rectfill(100,4,148,8, 2)
		printc(" \147:" .. gameworld.minutes	.. "'0".. gameworld.seconds,105,4,gameworld.textcolor,0,0)
				--rectfill(gameworld.c_min_x + 100, gameworld.c_min_y + 4, gameworld.c_min_x + 128, gameworld.c_min_y + 8, 2)
	else
						rectfill(100,4,148,8, 2)
		printc("  \147:".. gameworld.minutes .. "'".. gameworld.seconds ,103,4,gameworld.textcolor,0,0)
			--	rectfill(gameworld.c_min_x + 100, gameworld.c_min_y + 4, gameworld.c_min_x + 128, gameworld.c_min_y + 8, 2)
	end
end
end


__gfx__
012345670002200000022000000222000002222000222220000222200002222000000000000000000000000077777777077777700ffffff06666666600000000
89abcdef012222100022220000022220000222200002222000022220000222200000000000000000000000007dddddd77dddddd5f000000f1111111100000000
00700700711222150022220000111220001112200011122000111120001111200000000000000000000000007dddddd77dddddd5f000000f1111111100000000
000770000011111001122210001111000011111001111100001111100011111000d7770000000000000000007dd11dd77dddddd5f000000f1111111100000000
00077000011111100111111051111100001111105011110700111110001111100d77777000000000000000007dd11dd77dddddd5f000000f1111111100000000
00700700071111157011110501111107071111000011110005111170051117000d77272000000000000000007dddddd77dddddd5f000000f1111111100000000
00000000007000500011110007111000001770000111110000155000771110000d77777000000000000000007dddddd77dddddd5f000000f1111111100000000
000000000000000007700ddd0070555000555000055077700077700000555000000d7070000000000000000077777777055555500ffffff01111111100000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000444444446111111666666666000000000000000000000000
07000700070707000007000000000000000000000000000000000000000000000000000000000000444444446111111611111111000000000000000000000000
00707000007770000007000000707000000700000007700000000000000000000000000000000000444444446111111611111111000000000000000000000000
000a0000077a7700077a7700000a0000007a70000077770000000000000000000000000000000000444444446111111611111111000000000000000000000000
00707000007770000007000000707000000700000777777000000000000000000000000000000000444444446111111611111111000000000000000000000000
07000700070707000007000000000000000000007777777700000000000000000000000000000000444444446111111611111111000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000444444446111111611111111000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000444444446111111666666666000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000666666066666660066666660000000000000000
07000700070707000007000000000000000000000000000000000000000000000000000000000000000000006111111611111116611111110000000000000000
00707000007770000007000000707000000700000000000000000000000000000000000000000000000000006111111611111116611111110000000000000000
000a0000077a7700077a7700000a0000007a70000000000000000000000000000000000000000000000000006111111611111116611111110000000000000000
00707000007770000007000000707000000700000000000000000000000000000000000000000000000000006111111611111116611111110000000000000000
07000700070707000007000000000000000000000000000000000000000000000000000000000000000000006111111611111116611111110000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000006111111611111116611111110000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000006111111666666660066666660000000000000000
00070000000000000000000000000000000000000000000000000000000000000000000000000000000000006111111600000000000000000000000000000000
00777000000000000000000000000000000000000000000000000000000000000000000000000000000000006111111600000000000000000000000000000000
77777770000000000000000000000000000000000000000000000000000000000000000000000000000000006111111600000000000000000000000000000000
07777700000000000000000000000000000000000000000000000000000000000000000000000000000000006111111600000000000000000000000000000000
07707700000000000000000000000000000000000000000000000000000000000000000000000000000000006111111600000000000000000000000000000000
07000700000000000000000000000000000000000000000000000000000000000000000000000000000000006111111600000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000006111111600000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000666666000000000000000000000000000000000
01100110006666666666660011111116611111116666666611111116111111116111111111111111111111111111111100000000000000001111111111111111
1ff11ff1061111111111116011111116611111111111111111111116111111116111111117111111117111111111111100000000000000001111111111111111
49944994611111111111111611111116611111111111111111111116111111116111111111111111111111111111111100000000000000001111111111111111
01100110611111111111111611111116611111111111111111111116111111116111111111111111111111711111111100000000000000001111111111111111
00000000611111111111111611111116611111111111111111111116111111116111111111117711177111111111111100002200000000001117771111111111
00000000611111111111111611111116611111111111111111111116111111116111111111117711177111111111111100022220000000001177777111111111
00000000611111111111111611111160061111111111111111111116111111116111111111111111111111111111111100000f00000000001117177111711111
0000000061111111111111166666660000666666111111111111111666666666611111111111111111111111111111110000f000000000001177771117711711
000011d0d111000000111111111111000001111ddd1110000001111ddd111000000011101111000011111111000000000006d600000000000000000000060000
0011ddd0ddd101000100000000000010001ddd1000ddd100001ddd1000ddd100001111101111010017111111000000000006d600000000000000000000060000
001dddd0dddd0110100000000000000101d0000ee0000d1001d0000660000d100011111011110110111171110000000000066600000006666660000000060000
00000009000000001000000000000001000888800aaa0d100008888007770d10000000000000000011177711000600000000600000066dddddd6600000060000
11dd0d9a9d0ddd10100000000000000110c0880cc0a0000010508807707000001111011111011110117777710006000000006000000006666660000000000000
11dd09aaa90dd1101000000000000001d0c0800cc00bbb00d050800770055500111101100000111017777711006d600000000000000000000000000000000000
11dd09a7a90dd1111000000000000001d00f0cc00cc0b0d1d0070770077050d1111101000000011111777111006d600000000000000000000000000000000000
000000a7a00000001000000000000001d0ff0cc00cc000d1d0770770077000d1000000050005000011171111006d600000000000000000000000000000000000
011dd0fff0dd0d11100000000000000100fff00cc008800000777007700880000111100000000111000650001111111100000000000000000011111111111100
011dd04f40dd0d1110000000000000011d0f090cc088800d1d0706077088800d0111100000000111005006001dd1111100000000000660000100000000000010
0011d04440dd011010000000000000010100090cc0880c0d010006077088070d001110111011011000600500111111dd0ff00000007005001000000000000001
0000000440000000100000000000000101d09990c000c0d101d06660700070d1000000000000000000056000122111ddf00fffff00600d001000000000000001
00110100401111001000000000000001001000000a000010001000000700001000110111101111000006500012211111f00f0f0f0fff1f101000000000000001
0001011000111000100000000000000100110d00a01ddd1000110d00701ddd10000101111011100000600600111121110ff0000007fff1f01000000000000001
00000111100000001000000000000001000101d0a0111100000101d07011110000000111100000000060000011111111000000000f7fff101000000000000001
0000000000000000100000000000000100000111d000000000000111d000000000000000000000000000000011111111000000000ff7fff01000000000000001
00000000000000000000000000000000000000000000000000000000500500500570500000055000000550000888888000001110000000001000000055555551
00000000000000000000000000000000000000000000a000000000005506000005700500006005000050050088d7778800111110000000001000000055555551
00000000000000000ff0000000000000000000000009a90000000000605500000507050000600500005005008d777778001111100000000010000dddddddddd1
0000000000000000f00fffff0000000000000000000a7a0000000000600500000050500000066000000560008d772728000000000000000010000dddddddddd1
0000000000000000f00f0f0f000ddd00000000000009a90000000000000600000000070000065000000650008d77777811110111000000001555555555555551
00000000000000000ff0000000ddddd000000000000140000000000000060000000070000060050000600500888d787811110111000000001555555555555551
000000000000000000000000000d0dd000d00000000140000022d000000600000000070000600600005005000088888811110111000000001dddddddddddddd1
00000000000000000000000000dddd000dd00d000000100002ddd200000000000000070000066000000660000000000000000000000000001dddddddddddddd1
b4b4747474b4b4b4b4b47474747474b4b4b4b4b46400000000000000000000840000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b43400c500447474b4340000d0000084b4b4b4b46400000000000000000000840000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
64c7000000000000b1000000d0e6f684747474746400000000000000b50000840000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
64000000000000c6b1000000d0e7f784e6f60000b100000000000000b20000840000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
640000b500000004b10000b7d2c1c184e7f70000b1e500d5b200b700b100b7840000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
640000b200000000b10400000000008404040000b1e5c6d5b1000000b10000840000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
64b700b100000004b100000000000084d0d0d0d0b3e500d5b3000000b10000840000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
640000b1000000008424000000000084040000000000000000000000b10004840000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
640000b10000040484b4545424000084000000000000000000000000b300008400000000000000000000000000ffff0000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000f000000000000000000000000000000000
640400b1000000004474747464000084040000000000000000000000c5000084000000000000000000000000070000f000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077ff0000000000000000000000000000000000
640000b100000000000000c544c2048400000000b5000000b5000000000004840000000000000000000000000000f00000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ff00000000000000000000000000000000000
b42400b100000000000000000000008404000000b2000000b2000000000000840000000000000000000000000000f00000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007ff00000000000000000000000000000000000
b4b4546400b70000000000000000008404040404b1040404b100000000000084b1b10000000000000000000000000000000000000000000000000000cccccccc
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c000000c
b4b4b4b424000000b700b700000014b400000000b1000000b1000000b500048400000000000000000000000000000000000000000000000000000000c000000c
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c000000c
b4b4b4b464b5b5b5b5b5b5b5000084b400000000b1000000b100b700b200008400000000000000000000000000000000000000000000000000000000c000000c
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c000000c
b4b4b4b4b4545454545454545454b4b400000000b1000000b1000000b100008400000000000000000000000000000000000000000000000000000000c000000c
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccccccc
b4b4b47474747474747474747474b4b4b47474747474747474747474747474b40000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000037373737373737373737373737373737
b47434d000c5c5c5c5c50000000044b464000000000000000000000000c600840000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000037373737373737373737373737373737
640000d0000000000000000000000084640000000000000000000000000000840000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000037373737373737373737373737373737
64e6f6d0000000000000000000000084640000d0d0d0d0d0d0d0d0d0d0d0d0840000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000037373737373737373737373737373737
64e7f7d0b50000000000b50000000084640000000000000000142400000000840000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000037373737373737373737373737373737
b454545454c1c1c1c1c1c1c1c20000846404000000000000008464e50000d5840000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000037373737373737373737373737373737
b47474743400000000000000000004846400000000000000008464e50000d5840000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000037373737373737373737373737373737
6400000000000000000000000000008464040000b5b5b500008464e50000d5840000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000037373737373737373737373737373737
64000000000000000000000000000484b4c1c1c1c1c1c204048464e50000d5840000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000037373737373737373737373737373737
64002535c70000b5000000b5000000846400000000000000008464e50000d5840000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000037373737373737373737373737373737
64c7263600b700c000b700c000040484640000000000000014b464e50000d5840000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000037373737373737373737373737373737
b4c1c1c1c1c1c1c1c1c1c1c1c20000846400000000d2c1c174b464e50000d5840000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000037000000000000000000000000000000
64000000000000000000000000000484640000000000000000846400000000840000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
64c60000b700b700b700b70000000084640400000000000000846400e6f600840000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b4240000b5b5b5b5b5b5b500000014b4640000000000000000846400e7f700840000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b4b4545454545454545454545454b4b4545454545454545454545454545454545454000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000037
__label__
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111111111111111dd111111dd111111dd1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111111111111dddd1111dddd1111dddd111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111dddddd11dddddd11dddddd11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111117777777777777777777777771111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111170000000000000000000000007111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111d70000000000000000000000007111111111111111111111111111111111111111111111111111111111111111111111111111111111d11111
1111111111111dd70000000000000000000000007d11111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111111ddd70000000000000000000000007dd11111111111111111111111111111111111111111111111111111111111111111111111111111111111d1
111111111111ddd70000000000000000000000007ddd1111111dd111111dd111111dd111111dd111111dd111111dd111111dd111111dd111111111111dd11111
1111111111111dd70000000000000000000000007dddd11111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd1111dddd11111111111dd11111
11111111111111d700000000000000000000000007dddd111dddddd11dddddd11dddddd11dddddd11dddddd11dddddd11dddddd11dddddd11111111111111111
11111111111111170000000000000000000000000077777777777777777777777777777777777777777777777777777777777777777777771111111111111111
11111111111111170000111000111111111111000000000000000000000000000000000000055000000000000000000000000000000ddd007111111111111111
11111111111111d70011111001000000000000100000000000000000000000000000000000500500000000000000000000000000000ddd007111111111111111
1111111111111dd70011111010000000000000010000000000000000000000000000000000500500000000000000000000000000000ddd007d11111111111111
111111111111ddd70000000010000000000000010000000000000000000000000000000000056000000000000000000000000000000ddd007dd1111111111111
111111111111ddd711110111100000000000000100000000000000000000000000000000000650000000000000000000000000000000d0007ddd111111111111
1111111111111dd711110111100000000000000100000000000000000000000000000000006005000000000000000000000000000000d0007dddd11111111111
11d11111111111d711110111100000000000000100000000000000000000000000000000005005000000000000000000000000000000000007dddd1111111111
1dd11d11111111170000000010000000000000010000000000000000000000000000000000066000000000000000000000000000000000000077777711111111
11111111111111170000000010000000555555510000111000000000000000000000000000055000000000000000000000000000000000000000000071111111
1d111111111111d7000000001000000055555551001111100000a00000000000000000000060050000000000000000000000000000000000000000007d111111
1111111111111dd70000000010000dddddddddd1001111100009a90000000000000000000060050000000000000000000000000000000000000000007dd11111
111111111111ddd70000000010000dddddddddd100000000000a7a0000000000000000000006600000000000000000000000000000000000000000007ddd1111
1111dd111111ddd7000000001555555555555551111101110009a90000000000000000000006500000000000000000000000000000000000000000007ddd1111
1111dd1111111dd7000000001555555555555551111101110001400000000000000000000060050000000000000000000000000000000000000000007dd11111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111110000000000000000000001110000000000000111000000000000000011111111111100000111000001110000011111111111111111111
11111111111111111110777077707770077077701110777070707770111077007770777077001110000011107770111077701110777011111111111111111111
ddddddddddddddddddd070707070070070007000ddd0070070707000ddd07070700070707070ddd07070ddd07070ddd07070ddd00070dddddddddddddddddddd
ddddddddddddddddddd07700777007007770770ddddd07007770770dddd07070770077707070ddd07070ddd07070ddd07070dddd0770dddddddddddddddddddd
11111111111111111110707070700700007070001111070070707000111070707000707070701110777000007070000070700000007011111111111111111111
11111111111111111110707070707770770077701111070070707770111077707770707077701110070007007770070077700700777011111111111111111111
11111111111111111110000000000000000000001111000000000000111000000000000000001111000100000000000000000000000011111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111d77711111111111111111111111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111111111111111111111d777771111111111111111111111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111111111111111111111d772721111111111111111111111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111111111111111111111d777771111111111111111111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111111111111111111111111d7171111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111100000000011100000000000000000000000001111000000000000000000000000000000001111111111111111111111111111
11111111111111111111111111107770707011107770077007707070707077701110077077707770777077707770777077701111111111111111111111111111
11111111111111111111111111107070707011100700707070007070707070701110700007000700777070707000707007001111111111111111111111111111
11111111111111111111111111107700777011110700707077707770707077701110777007010700707077707700770007011111111111111111111111111111
11111111111111111111111111107070007011100700707000707070707070701110007007000700707070007000707007011111111111111111111111111111
11111111111111111111111111107770777011107700770077007070077070701110770007007770707070107770707007011111111111111111111111111111
11111111111111111111111111100000000011100000000000000000000000001110000100000000000000100000000000011111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111100010000000000000000000000000000000000000000000000000001111111111111111111111111111111111111
11111111111111111111111111111111111007000700777007707770707007707070077077707700777070700700111111111111111111111111111111111111
11111111111111111111111111111111111070007070070070707000707070007070707070707070700070700070111111111111111111111111111111111111
11111111111111111111111111111111111070107070070070707700707077707770707077707070770070701070111111111111111111111111111111111111
11111111111111111111111111111111111070007000070070707000707000707070707070007070700077700070111111111111111111111111111111111111
11111111111111111111111111111111111007000770070077007010077077007070770070107770777007000700111111111111111111111111111111111111
11111111111111111111111111111111111100010000000000000011000000000000000000100000000000010001111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222220000000000000000000002222000000022220000000002222000000000000000000002222222222222222222222222222
22222222222222222222222222222220777077707770077007702220077777002220777007702220077077707770777077702222222222222222222222222222
22222222222222222222222222222220707070707000700070002220770707702220070070702220700007007070707007002222222222222222222222222222
22222222222222222222222222222220777077007700777077702220777077702222070070702220777007007770770007022222222222222222222222222222
22222222222222222222222222222220700070707000007000702220770707702222070070702220007007007070707007022222222222222222222222222222
22222222222222222222222222222220702070707770770077002220077777002222070077002220770007007070707007022222222222222222222222222222
22222222222222222222222222222220002000000000000000022222000000022222000000022220000200000000000000022222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111dd70000000000000000000000000000000000000000000000007d11111111111111111111d7000000007dd111111ddddd1111111dd7000000007dd11111
111111d7000000000000000000000000000000000000000000000000711111111111111111111117000000007d11111111ddd111111111d7000000007d111111
111111170000000000000000000000000000000000000000000000007111111111111111111111170000000071111111111d1111111111170000000071111111
11111117000000000000000000000000000000000000000000777777111111111111111111111117011001107111111111111111111111170110011071111111
111111d7000000000000000000000000000000000000000007dddd111111111111111111111111d71ff11ff17111111111111111111111171ff11ff17d111111
11111dd700000000000000000000000000000000000000007dddd111111111111111111111111dd7499449947d11111111111111111111d7499449947dd11111
1111ddd700000000000000000000000000000000000000007ddd111111111111111111111111ddd7011001107dd111111111111111111dd7011001107ddd1111
1111ddd700000000000000000000000000000000000000007dd1111111111111111111111111ddd7000000007ddd1111111dd1111111ddd7000000007ddd1111
11111dd700000000000000000000000000000000000000007d111111111111111111111111111dd7000000007dddd11111dddd11111dddd7000000007dd11111
111111d70000000000000000000000000000000000000000711111111111111111d11111111111d70000000007dddd111dddddd111dddd70000000007d111111
11111117000000000000000000000000000000000000000071111111111111111dd11d1111111117000000000077777777777777777777000000000071111111
11111111777777000000000000000000000000000077777711111111111111111111111111111117000000000000000000000000000000000000000071111111
1111111111dddd7000000000000000000000000007dddd11111111111111111111111111111111d700000000000000000000000000000000000000007d111111
11111111111dddd70000000000000000000000007dddd11111111111111111111111111111111dd700000000000000000000000000000000000000007dd11111
111111111111ddd70000000000000000000000007ddd11111111111111111111111111111111ddd700000000000000000000000000000000000000007ddd1111
1111111111111dd70000000000000000000000007dd111111111111111111111111111111111ddd700000000000000000000000000000000000000007ddd1111
11111111111111d70000000000000000000000007d11111111111111111111111111111111111dd700000000000000000000000000000000000000007dd11111
1111111111111117000000000000000000d0000071111111111111111111111111111111111111d700000000000000000000000000000000000000007d111111
111111111111111700000000000000000dd00d007111111111111111111111111111111111111117000000000000000000000000000000000000000071111111
11111111111111117777777777777777777777771111111111111111111111111111111111111111777777777777777777777777777777777777777711111111
11d11111111111111dddddd11dddddd11dddddd1111111111d1111111111111111111111111111111dddddd11dddddd11dddddd11dddddd11dddddd111111111
111111111111111111dddd1111dddd1111dddd11111111111111111111111111111111111111111111dddd1111dddd1111dddd1111dddd1111dddd1111111111
111111d111111111111dd111111dd111111dd1111111111111111111111111111111111111111111111dd111111dd111111dd111111dd111111dd11111111111
1dd1111111111111111111111111111111111111111111111111dd11111111111111111111111111111111111111111111111111111111111111111111111111
1dd1111111111111111111111111111111111111111111111111dd11111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111

__gff__
0000000000000000000000010108010000000000000000000000000101000000000000000000000000000001010100004000000000000000000000010000000002010101010101010101010000000000000000000000000000000110101010000000000000000000000000004001808010014000000000000000000400008080
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
4b4b4747474b4b4b4b4b4b4b4b4b4b4b4b4b47474747474b4b4b4b4b4b4b4b4b4747474747474b4b4b4b4b4b4b4b4b4b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4b460000004447474747474747474b4a4b4600005c0000484b4b4b4b4b4b4b4b000000000000484b4b4b4747474747470000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f467c6e6f0d0000007a0000005c444b4b467200000000484b4b4b4b4b4f4b4b000000000000484b4b4300007a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4946007e7f0d750000790000000000484b472c00000000484b4b4b474b4b4b4b00006c000000484b430000007a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4b43404040400000006a000000720048464300007b000048494b4600484b4b4b004040000000444300000000790000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
460000000000000000000000000000484677000000004c484b4b4673484b4b4b5b00000000000000000000006a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
46000000000000007b000000005b00484600000000002d4b4b4b4b454b4b4b4b404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4600007374000000000000414542004846000000000000484b4b4b4b4b4b494b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
460000414200007c000000484b460048460000000c5b5b484b494b4b4b4b4b4b5b5b5b5b005b5b0000000000000d0d0d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4600004443000000007c0048494640484600000000404044474747474b4b4b4b404040404040407b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4600000000007b00000000484b4600484640000000000000006a007a484b4b4b000000000000000000000d0d0d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
460000000000004c007400484b46004846000000000000000000006a4447474b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4600000000000041454200485a4600484600000000000000000000000d000048000000000000000d0d0d000000000d0d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
460000000000414b4f464044474340484b4542005b007b005b0000000d6e6f48000000000000000000000000000d6e6f0d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4b42000074414b4b4b460000000000484b4b46000c0000002b5b00000d7e7f48000000000d0d0d0000000000000d7e7f0d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4a4b450e454b494b4b4b0e45450e0e4b4b4b467070707000484240404145454b454542000000000000000000414545454500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4b4b4747474747474747474747474b4b4b47474b4b4b4b4b4b4b4b4b4b4b4b4b4b4b47474747474b4b4b4b47474747474b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4b430000000000000000000000004447467c0044474747474747474747474b494b430000000000444b4b460000000d0d4800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
460000007374000000000000000d6e6f466e6f0d000000000000777a7700444b460000000000000048474600000d6e6f4800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
460000004142000000005b00000d7e7f467e7f0d000000000000007a0000004846000000000000001b5c1b00000d7e7f4800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
46000000484b4200007b0c0000004145464040000000007c0000007900000048460000005b0000001b6c1b00004040404800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4640402d4747471c1c1c45420000484b46000000007b0000007b006a007b0048464000002b5e005d1b401b00000000004800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
46000000005c000000004446402d4b4e4600007200005b5b5b5b5b5b00000048460000001b0000001b001b40400000004800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
467b0000000000000000001b0000484b46000000000041454545454200004048464000001b5e005d1b401b00000000004800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4600000000000000000000482c40484b46000000000044474747474300000048460000001b0000003b003b007b0000004800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4b1c4542005b004c0000001b0000484b4652537c000000000000000000004048464000001b00000000400000000000004800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
467744471c1c1c1c2c40401b402d4b4946626300000000000000000000000048460000001b0000000000000000007b004800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4600000000007a000000001b005c484b49454200000000000000000000004048464000001b000000000000000000005b4800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4600000058596a000000001b6c00484b4b4b46000000007c00005b0000000048460000001b007b00007b00007b005b414b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4600000068690000005b41467b00484b4b5a4600007b00007b002b5b7b000048464000001b00000000000000005b414b4b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4b4545420000004145454b460000484b4b4b460000000000005b484200005b48460000001b0000000000000000414b4b4b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4b4b4b46000000484b4b4b460000484b4b4b43000000000000414b460000414b4b454545460000000000000000484b4b4b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00060000250412b021330013d00100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00040000191411f52124101211011c7000a6000a6000a600000000e300000000000000000000002c500000000000000000026000b600000000000000000000000000000000000000000000000000000000000000
000400000164003510150100f62012510127000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000016400350003600036200c500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010200002e0202f010320201f7501f730267202a710337100b120051203f10002700000000000000000000002a400000000000000000000000000000000000000000000000000000000000000000000000000000
010200000f713172200d6400f6300d3200f3100d3100f3200a2300c61000025000350005500044000230001000030000600005000040000200004000050000600007000060000500003000030000200001000040
000200000475304653056530565305753265002b500315001d500265002e500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000d0300f02013720187201d7202472025720207401d7201361013610166101461011610116101462002150061400714005150061400e15014150000000000000000000000000000000000000000000000
0002000029052290422a0422b0522d052330523a05228032290322b0222d03230032350323b0222a0122a0122a0122d0122f0123101237012390122e002230000000000000000000000000000000000000000000
__music__
00 01424344

