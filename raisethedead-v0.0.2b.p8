pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
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
}

--music tracks
mus=
{

}

gameworld=
{
	startpoint_x = 20,
	startpoint_y = 80,
	c_min_x = 0,
	c_min_y = 0,
	c_max_x = 190,
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
		if fget(mget((self.x+(offset))/8,(self.y+i)/8),0) then
			self.dx=0
			self.x=(flr(((self.x+(offset))/8))*8)-(offset)
			return true
		end
	--elseif self.dx<0 then
		if fget(mget((self.x-(offset))/8,(self.y+i)/8),0) then
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
			if gameworld.c_min_y < 384 then
			gameworld.startpoint_y = gameworld.startpoint_y + 128
			gameworld.c_min_y = gameworld.c_min_y + 128
			gameworld.currentlevel = gameworld.currentlevel - 1
			reset()
		else
			gameworld.startpoint_y = 80
			gameworld.startpoint_x = gameworld.startpoint_x + 128
			gameworld.c_min_y = 0
			gameworld.currentlevel = gameworld.currentlevel	- 1
			gameworld.c_min_x = gameworld.c_min_x + 128
			reset()
		end
			return true
		end
	--elseif self.dx<0 then
		if fget(mget((self.x-(offset))/8,(self.y+i)/8),7) and havekey  or btn(0) and btn(1) and btn(2) and btn(3) and ticks > 50 then
			if gameworld.c_min_y < 384 then
			gameworld.startpoint_y = gameworld.startpoint_y + 128
			gameworld.c_min_y = gameworld.c_min_y + 128
			gameworld.currentlevel = gameworld.currentlevel - 1
			reset()
		else
			gameworld.startpoint_y = 80
			gameworld.startpoint_x = gameworld.startpoint_x + 128
			gameworld.c_min_y = 0
			gameworld.currentlevel = gameworld.currentlevel	- 1
			gameworld.c_min_x = gameworld.c_min_x + 128
			reset()
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
		if fget(tile,0) or (fget(tile,1) and self.dy>=0 and not btn(3)) then
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
		if fget(tile,4) or self.y > gameworld.c_min_y + 123 then
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
			reset()
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
		if fget(tile,4) then
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
			reset()
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
		if fget(mget((self.x+i)/8,(self.y-(self.h/2))/8),0) then
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
		max_dy=2.5,--max y speed

		jump_speed=-1.25,--jump veloclity
		acc=0.065,--acceleration
		dcc=0.8,--decceleration
		air_dcc=1,--air decceleration
		grav=0.15,
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
				if btn(5) or self.stompedem then
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
			collide_death(self)
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
function m_cam(target)
	local c=
	{
		tar=target,--target to follow.
		pos=m_vec(target.x,target.y),

		--how far from center of screen target must
		--be before camera starts following.
		--allows for movement in center without camera
		--constantly moving.
		pull_threshold=16,

		--min and max positions of camera.
		--the edges of the level.
		pos_min=m_vec(gameworld.c_min_x, gameworld.c_min_y),
		pos_max=m_vec(gameworld.c_max_x,gameworld.c_max_y),

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
	p1=m_player(gameworld.startpoint_x, gameworld.startpoint_y)
	p1:set_anim("walk")
	cam=m_cam(p1)
	lasthitwashead = false
	stompedem = false
	havekey = false
	grounded = false
	p1.jump_hold_time = 20
	deadticks = 0
	gameworld.textcolor = 7
	resume_timer("timer1")
end

--p8 functions
--------------------------------

function _init()

	init_timers()
	reset()
	local last_int = 0
	add_timer(
		"timer1",
		9999,
		function (dt,elapsed,length)
			local i = flr(elapsed)
			if i > last_int then
				gameworld.minutes = flr((i / 2) /  60)
				gameworld.seconds = flr(i / 2) - (gameworld.minutes * 60)
				if gameworld.phase == 3 and not active then
					pause_timer("timer1")
				end
			end
		end,
		function ()
			print("done!")
			sfx(10)
		end
		)
end

function _update60()
	if gameworld.phase == 2 then
	ticks+=1
	p1:update()
	cam:update()
	--demo camera shake
	if(btnp(4))cam:shake(15,2)
end

if gameworld.phase ==3 then
	deadticks += 1
	if btnp(5) and deadticks > 60 then
			gameworld.phase =2
			reset()
			make_smoke_ps(p1.x,p1.y + 0)
			make_smoke_ps(p1.x,p1.y + 3)
			make_smoke_ps(p1.x,p1.y + -3)
			make_smoke_ps(p1.x,p1.y + -6)
			make_smoke_ps(p1.x + 3,p1.y + 0)
			make_smoke_ps(p1.x - 3,p1.y + 0)
	end
end
	update_psystems()
	update_timers()
end

function _draw()

	cls(0)

	camera(gameworld.c_min_x,gameworld.c_min_y)

	map(0,0,0,0,128,128)

	p1:draw()
  --spr(8, local.x, local.y -5)--
	for ps in all(particle_systems) do
		draw_ps(ps)
	end
	if gameworld.phase == 3 then
		rectfill(gameworld.c_min_x, gameworld.c_min_y + 60, gameworld.c_min_x + 128, gameworld.c_min_y + 80, 2)
		printc("\140", gameworld.c_min_x + 64, gameworld.c_min_y +65, 7, 0, 0)
		printc(" r.i.p. in peace", gameworld.c_min_x + 64, gameworld.c_min_y + 75, 7, 0, 0)
		if deadticks > 60 then
			printc("press \151 to respawn", gameworld.c_min_x + 64, gameworld.c_min_y +85, 7, 0, 0)
		end
	end

	--hud
	camera(0,0)
	if gameworld.phase == 3 then	gameworld.textcolor = 13 end
	if gameworld.seconds < 10 then
		printc("floor:".. gameworld.currentlevel .. "  deaths:" .. gameworld.deaths .. "  \147:" .. gameworld.minutes	.. "'0".. gameworld.seconds,64,4,gameworld.textcolor,0,0)
	else
		printc("floor:".. gameworld.currentlevel .. "  deaths:" .. gameworld.deaths .. "  \147:"..gameworld.minutes .."'".. gameworld.seconds ,64,4,gameworld.textcolor,0,0)
	end
end


__gfx__
012345670002200000022000000222000002222000222220000222200002222000000000000000000000000077777777077777700ffffff00000000000000000
89abcdef012222100022220000022220000222200002222000022220000222200000000000000000000000007dddddd77dddddd5f000000f0000000000000000
00700700711222150022220000111220001112200011122000111120001111200000000000000000000000007dddddd77dddddd5f000000f0000000000000000
000770000011111001122210001111000011111001111100001111100011111000d7770000000000000000007dd11dd77dddddd5f000000f0000000000000000
00077000011111100111111051111100001111105011110700111110001111100d77777000000000000000007dd11dd77dddddd5f000000f0000000000000000
00700700071111157011110501111107071111000011110005111170051117000d77272000000000000000007dddddd77dddddd5f000000f0000000000000000
00000000007000500011110007111000001770000111110000155000771110000d77777000000000000000007dddddd77dddddd5f000000f0000000000000000
000000000000000007700ddd0070555000555000055077700077700000555000000d7070000000000000000077777777055555500ffffff00000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000444444447111111777777777000000000000000000000000
07000700070707000007000000000000000000000000000000000000000000000000000000000000444444447d111117111dddd1000000000000000000000000
00707000007770000007000000707000000700000000000000000000000000000000000000000000444444447dd111171111dd11000000000000000000000000
000a0000077a7700077a7700000a0000007a70000000000000000000000000000000000000000000444444447dd111d711111111000000000000000000000000
00707000007770000007000000707000000700000000000000000000000000000000000000000000444444447d111dd711111111000000000000000000000000
070007000707070000070000000000000000000000000000000000000000000000000000000000004444444471111dd711dd1111000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000044444444711111d71dddd111000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000444444447111111777777777000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000777777077777770077777770000000000000000
07000700070707000007000000000000000000000000000000000000000000000000000000000000000000007111111711ddd117711ddd110000000000000000
007070000077700000070000007070000007000000000000000000000000000000000000000000000000000071111117111d11177111d1110000000000000000
000a0000077a7700077a7700000a0000007a70000000000000000000000000000000000000000000000000007d1111d711111117711111110000000000000000
00707000007770000007000000707000000700000000000000000000000000000000000000000000000000007dd11dd711111117711111110000000000000000
07000700070707000007000000000000000000000000000000000000000000000000000000000000000000007d1111d7111d11177111d1110000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000007111111711ddd117711ddd110000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000007111111777777770077777770000000000000000
00070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07707700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01100110007777777777770011111117711111117777777711111117111111117111111111111111111111111111111100000000000000001111111111111111
1ff11ff107dddd1111dddd7011111117711111111dddddd1111111d7111111117d1111111d11111111d111111111111100000000000000001111111111111111
499449947dddd111111dddd7111111d77d11111111dddd1111111dd7111111117dd1111111111111111111111111111100000000000000001111111111111111
011001107ddd11111111ddd711111dd77dd11111111dd1111111ddd7111111117ddd111111111111111111d11111111100000000000000001111111111111111
000000007dd1111111111dd71111ddd77ddd1111111111111111ddd7111dd1117ddd11111111dd111dd11111111111110000220000000000111ddd1111111111
000000007d111111111111d7111dddd77dddd1111111111111111dd711dddd117dd111111111dd111dd1111111111111000222200000000011ddddd111111111
00000000711111111111111711dddd7007dddd1111111111111111d71dddddd17d11111111111111111111111111111100000f0000000000111d1dd111d11111
0000000071111111111111177777770000777777111111111111111777777777711111111111111111111111111111110000f0000000000011dddd111dd11d11
000011d0d111000000111111111111000001111ddd1110000001111ddd11100000001110111100001111111100000000000ddd00000000000000000000060000
0011ddd0ddd101000100000000000010001ddd1000ddd100001ddd1000ddd10000111110111101001d11111100000000000ddd00000000000000000000060000
001dddd0dddd0110100000000000000101d0000ee0000d1001d0000660000d1000111110111101101111d111000d0000000ddd0000000dddddd0000000060000
00000009000000001000000000000001000888800aaa0d100008888007770d100000000000000000111ddd11000d0000000ddd00000dddddddddd00000060000
11dd0d9a9d0ddd10100000000000000110c0880cc0a000001050880770700000111101111101111011ddddd100ddd0000000d00000000dddddd0000000000000
11dd09aaa90dd1101000000000000001d0c0800cc00bbb00d05080077005550011110110000011101ddddd1100ddd0000000d000000000000000000000000000
11dd09a7a90dd1111000000000000001d00f0cc00cc0b0d1d0070770077050d1111101000000011111ddd11100ddd00000000000000000000000000000000000
000000a7a00000001000000000000001d0ff0cc00cc000d1d0770770077000d10000000500050000111d111100ddd00000000000000000000000000000000000
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
b4b4747474b4b4b4b4b47474747474b464fb00000000000000000000000000840000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b43400c500447474b434000000000084000000000000000000000000000000840000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
64c7000000000000b1000000c7e6f684000000000000000000000000b50000840000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
64000000000000c6b1000000b5e7f784000000000000000000000000c00000840000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
640000b500000004b10000b7d2c1c18400005700c0e500d5c000b700b100b7840000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
640000b200000000b104000000000084e6f60000c0e5c6d5c0000000b10000840000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
64b700b100000004b100000000000084e7f70000c0e500d5c0000000b10000840000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
640000b1000000008424000000000084040400000000000000000000b10004840000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
640000b10000040484b4545424000084000000000000000000000000b100008400000000000000000000000000ffff0000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000f000000000000000000000000000000000
640400b1000000004474747464000084040000000000000000000000c0000084000000000000000000000000070000f000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077ff0000000000000000000000000000000000
640000b10000000000c5c5c544c2048400000000b5000000b5000000c50004840000000000000000000000000000f00000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ff00000000000000000000000000000000000
b42400b100000000000000000000008404000000c0000000c0000000000000840000000000000000000000000000f00000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007ff00000000000000000000000000000000000
b4b4546400000000000000000000008404040404b1040404b100000000000084b1b10000000000000000000000000000000000000000000000000000cccccccc
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c000000c
b4b4b4b424b70000b700b700000014b400000000b1000000b1000000b500048400000000000000000000000000000000000000000000000000000000c000000c
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c000000c
b4b4b4b464b5b5b5b5b5b5b5000084b400000000b1000000b100b700c000008400000000000000000000000000000000000000000000000000000000c000000c
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c000000c
b4b4b4b4b4545454545454545454b4b400000000b1000000b10000000000008400000000000000000000000000000000000000000000000000000000c000000c
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccccccc
b4b4b47474747474747474747474b4b4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000037373737373737373737373737373737
b474340000c5c500c5c500c5c50044b4640000000000000000000000000000840000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000037373737373737373737373737373737
64000057000000000000000000000084640000000000000000000000000000840000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000037373737373737373737373737373737
64e6f600000000000000000000000084640000000000000000000000000000840000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000037373737373737373737373737373737
64e7f7c7b50000b50000b50000000084640000000000000000000000000000840000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000037373737373737373737373737373737
b454545454c1c1c1c1c1c1c1c2000084640000000000000000000000000000840000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000037373737373737373737373737373737
b4747474340000000000000000000484640000000000000000000000000000840000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000037373737373737373737373737373737
64000000000000000000000000000084640000000000000000000000000000840000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000037373737373737373737373737373737
64000000000000000000000000000484640000000000000000000000000000840000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000037373737373737373737373737373737
64002535c70000b5000000b500000084640000000000000000000000000000840000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000037373737373737373737373737373737
64c7263600b700c000b700c000040484640000000000000000000000000000840000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000037373737373737373737373737373737
b4c1c1c1c1c1c1c1c1c1c1c1c2000084640000000000000000000000000000840000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000037000000000000000000000000000000
64000000000000000000000000000484640000000000000000000000000000840000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
64c60000b700b700b700b70000000084640000000000000000000000000000840000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b4240000b5b5b5b5b5b5b500000014b4640000000000000000000000000000840000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b4b4545454545454545454545454b4b4545454545454545454545454545454545454000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000037
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000007770770070700000000077707770077077700770000077707000777077707770077077707770777077700000000000000000000000
00000000000000000000007070707070700000000077700700700070707070000070707000707007007000707070707770700070700000000000000000000000
00000000000000000000007770707070700000000070700700700077007070000077707000777007007700707077007070770077000000000000000000000000
00000000000000000000007070707077700000000070700700700070707070000070007000707007007000707070707070700070700000000000000000000000
00000000000000000000007070777007000700000070707770077070707700000070007770707007007000770070707070777070700000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00dd1500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00d11150000000000000000000000000000000000000000000000000000000000000000000000000000000000001100000000000000000000000000000000000
00dd1500000000505000005050000050500000505000005050000050500000505000005050000050500000505001100000000050500000505000005050000050
00d11150500505151005051510050515100505151005051510050515100505151005051510050515100505151000000000050515100505151005051510050515
00dd1115155151111551511115515111155151111551511115515111155151111551511115515111155151111500000100515111155151111551511115515111
00d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d100000000d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1
00dd1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d001000001d1d1d1d1d1d1d1d1d1d1d1d1d1d1d
000ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd00000000dddddddddddddddddddddddddddddd
005005005000000000000000000000000000000000000000000000000050050050000000000000000050050050d1d50000000051dd0000000000000000000051
005506000000000000000000000000000000000000000000000000000055060000000000000000000055060000dd11500000511d1d000001000000900000511d
006055000000000000000000000000000000000000000000000000000060550000000000000000000060550000d1d50000000511dd000000000009a900000511
006005000000000000000000000000000000000000000000000000000060050000000000000000000060050000dd11500000511d1d00000000000a7a0000511d
000006000000000000000000000000000000000000000000000000000000060000000000000000000000060000d1d11500000511dd000000000009f900000511
000006000000000000000000000000000000000000000000000000000000060000000000000000000000060000dd11500000005d1d000000000001400000005d
000006000000000000000000000000000000000000000000000000000000060000000000000000000000060000d1d11500000511dd0000001000014000000511
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd15000000005d1d000000000000100000005d
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d1d50000000051dd0000000000000000000051
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd11500000511d1d011000000000000000511d
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d1d50000000511dd0110000000000000000511
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd11500000511d1d000000000000000000511d
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d1d11500000511dd0000010000000000000511
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd11500000005d1d000000000000000000005d
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d1d11500000511dd0010000000000000000511
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd15000000005d1d000000000000000000005d
100110011001100110000000000000000000000000000000000000000000000000000000000000000000000000d1d50000000051dd0000000000000000000051
f11ff11ff11ff11ff1000000000000000000000000000000000000000000000000000000000000000000000000dd11500000511d1d000000000000900000511d
944994499449944994000000000000000000000000000000000000000000000000000000000000000000000000d1d50000000511dd000000000009a900000511
100110011001100110000000000000000000000000000000000000000000000000000000000000000000000000dd11500000511d1d00000000000a7a0000511d
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d1d11500000511dd000000000009f900000511
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd11500000005d1d000000000001400000005d
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d1d11500000511dd0000000000014000000511
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd15000000005d1d000000000000100000005d
d0d111000000000000000000000000000001100110000000000110011000000000011001100000000001100110d1d50000000051dd0000000000000000000051
d0ddd101000000000000000000000000001ff11ff1000000001ff11ff1000000001ff11ff1000000001ff11ff1dd11500000511d1d000001000000000000511d
d0dddd011000000000000000000000000049944994000000004994499400000000499449940000000049944994d1d50000000511dd0000000000000000000511
090000000000000000000000000000000001100110000000000110011000000000011001100000000001100110dd11500000511d1d000000000000000000511d
9a9d0ddd1000000000000000000000000000000000000000000000000000000000000000000000000000000000d1d11500000511dd0000000000000000000511
aaa90dd11000000000000000000000000000000000000000000000000000000000000000000000000000000000dd11500000005d1d000000000000000000005d
a7a90dd11100000000000000000000000000000000000000000000000000000000000000000000000000000000d1d11500000511dd0000001000000000000511
a7a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd15000000005d1d000000000000000000005d
fff0dd0d1100000000000000000000000000000000000000000000000000000000000000000000000000000000d1d50000000051dd0000000000000000000051
4f40dd0d1100000000000000000000000000000000000000000000000000000000000000000000000000000000dd11500000511d1d011000000000900000511d
4440dd011000000000000000000000000000000000000000000000000000000000000000000000000000000000d1d50000000511dd011000000009a900000511
044000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd11500000511d1d00000000000a7a0000511d
004011110000000000000000000000000000000000000000000000000000000000000000000000000000000000d1d11500000511dd000001000009f900000511
100011100000000000000000000000000000000000000051110000000000000000000000000000000000000000dd11500000005d1d000000000001400000005d
111000000000000000000000000000000000000000000061711000000000000000000000000033500000000000d1d11500000511dd0010000000014000000511
000000000000000000000000000000000000000000000627871700000000000000000000000355530000000000dd15000000005d1d000000000000100000005d
00000000000000000000000000000000000000000000005771600000000dddddddddddddddddddddd000000000d1d50000000051dd0000000000000000000051
0000000000000000000000000000000000000000000000066600000000dd1d1d1dd1d1d1d1d1d1d1dd00000000dd11500000511d1d000000000000000000051d
0000000000000000000000000000000000000000000000059900000000d1d111111d1d1d1d1d1d1d1d00000000d1d50000000511dd0000505000005050000051
0000000000000000000000000000000000000000000000055000000000dd11151551111515515111dd00000000dd11500000511d1d050515100505151005051d
0000000000000000000000000000000000000000000000440000000000d1d15050015150500505111d00000000d1d11500000511dd5151111551511115515111
0000000000000000000000000000000000000000000000000000000000dd15000005050000000051dd00000000dd11500000005d1dd1d1d1d1d1d1d1d111111d
0000500000000000000000000000000000000000000000000000000000d1d15000000000000005111d00000000d1d11500000511dd1d1d1d1d1d1d1d1dd1d1d1
0005500500000000000000000000000000000000000000000000000000dd15000000000000000051dd00000000dd15000000005d1ddddddddddddddddddddddd
ddddddddd0000000000000000000000000000000000000000000000000d1d5000000000000000051dd00000000d1d50000000051dd5005005000000000000000
1dd1d1d1dd000000000000000000000000000000000000000000000000dd1150000110000000511d1d00000000dd11500000511d1d5506000000000000000000
111d1d1d1d000000000000000000000000000000000000000000000000d1d5000001100000000511dd00000000d1d50000000511dd6055000000000000000000
15515111dd000000000000000000000000000000000000000000000000dd1150000000000000511d1d00000000dd11500000511d1d6005000000000000000000
500505111d000000000000000000000000000000000000000000000000d1d1150000000100000511dd00000000d1d11500000511dd0006000000000000000000
00000051dd000000000000000000000000000000000000000000000000dd1150000000000000005d1d00000000dd11500000005d1d0006000000000000000000
000005111d000000000000000000000000000000000000000000000000d1d1150000100000000511dd00000000d1d11500000511dd0006000000000000000000
00000051dd000000000000000000000000000000000000000000000000dd1500000000000000005d1d00000000dd15000000005d1d0000000000000000000000
00000051dd000000000000000000000000000011d0d111000000000000d1d5000000000000000051dd01100110d1d50000000051dd0000000000000000000000
0000051d1d0000000000000000000000000011ddd0ddd1010000000000dd1150000000010000511d1d1ff11ff1dd11500000511d1d0000000000000000000000
00000051dd000000000000000000000000001dddd0dddd011000000000d1d5000000000000000511dd49944994d1d50000000511dd0000000000000000000000
5005051d1d000000000000000000000000000000090000000000000000dd1150000000000000511d1d01100110dd11500000511d1d0000000000000000000000
15515111dd00000000000000000000000011dd0d9a9d0ddd1000000000d1d1150000000000000511dd00000000d1d11500000511dd0000000000000000000000
d111111d1d00000000000000000000000011dd09aaa90dd11000000000dd1150000000000000005d1d00000000dd11500000005d1d0000000000000000000000
1dd1d1d1dd00000000000000000000000011dd09a7a90dd11100000000d1d1150000000010000511dd00000000d1d11500000511dd0000000000000000000000
ddddddddd0000000000000000000000000000000a7a000000000000000dd1500000000000000005d1d00000000dd15000000005d1d0000000000000000000000
0000000000000000000000000000000000011dd0fff0dd0d1100000000d1d5000000000000000051dd00000000d1d50000000051ddddddddd000000000000000
0000000000000000000000000000000000011dd04f40dd0d1100000000dd1150000110000000511d1d00000000dd11500000511d1dd1d1d1dd00000000000000
00000000000000000000000000000000000011d04440dd011000000000d1d5000001100000000511dd00000000d1d50000000511dd1d1d1d1d00000000000000
0000000000000000000000000000000000000000044000000000000000dd1150000000000000511d1d00000000dd11500000511d1d515111dd00000000000000
0000000000000000000000000000000000001101004011110000000000d1d1150000000100000511dd00000000d1d11500000511dd0505111d00000000000000
0000000000000000000000000000000000000101100011100000000000dd1150000000000000005d1d00000000dd11500000005d1d000051dd00000000000000
0000000000000000000000000000000000000001111000000000000000d1d1150000100000000511dd00000000d1d11500000511dd0005111d00000000000000
0000000000000000000000000000000000000000000000000000000000dd1500000000000000005d1d00000000dd15000000005d1d000051dd00000000000000
0000000000000000000000000000000000000000000000000000000000d1d5000000000000000051dd00000000d1d50000000051dd00000000ddddddd0000000
0000000000000000000000000000000000000000000000000000000000dd1150000000010000511d1d00000000dd11500000511d1d01100000d1d1d1dd000000
0000000000000000000000000000000000000000000000000000000000d1d5000000000000000511dd00000000d1d50000000511dd011000001d1d1d1d000000
0000000000000000000000000000000000000000000000000000000000dd1150000000000000511d1d00000000dd11500000511d1d00000000515111dd000000
0000000000000000000000000000000000000000000000000000000000d1d1150000000000000511dd00000000d1d11500000511dd000001000505111d000000
0000000000000000000000000000000000000000000000000000000000dd1150000000000000005d1d00000000dd11500000005d1d00000000000051dd000000
0000000000000000000000000000000000003350000050000000000000d1d1150000000010000511dd00000000d1d11500000511dd001000000005111d000000
0000000000000000000000000000000000035553000550050000000000dd1500000000000000005d1d00000000dd15000000005d1d00000000000051dd000000
000000000000000000000000000dddddddddddddddddddddd000000000d1d5000000000000000051dd00000000d1d50000000051dd0000000000000000dddddd
00000000000000000000000000dd1d1d1dd1d1d1d1d1d1d1dd00000000dd1150000110000000511d1d00000000dd11500000511d1d0000000000000100d1d1d1
00000000000000000000000000d1d111111d1d1d1d1d1d1d1d00000000d1d5000001100000000511dd00000000d1d50000000511dd00000000000000001d1d1d
00000000000000000000000000dd11151551111515515111dd00000000dd1150000000000000511d1d00000000dd11500000511d1d0000000000000000515111
00000000000000000000055500d1d15050015150500505111d00000000d1d1150000000100000511dd00000000d1d11500000511dd0000000000000000050511
00000000000000000000555550dd15000005050000000051dd00000000dd1150000000000000005d1d00000000dd11500000005d1d0000000000000000000051
00000000000000000000050550d1d15000000000000005111d00000000d1d1150000100000000511dd00000000d1d11500000511dd0000000000000010000511
00000000000000000000555500dd15000000000000000051dd00000000dd1500000000000000005d1d00000000dd15000000005d1d0000000000000000000051
0000000000000000000ddddddd0000000000000000000051dd00000000dd15000000000000000051dd01100110d1d50000000051dd0000000000000000000000
000000000000000000dd1d1d1d000001000000010000511d1d00000000d11150000000000000051d1d1ff11ff1dd11500000511d1d0000000000000000011000
000000000000000000d1d111110000000000000000000511dd00000000dd15000000005050000051dd49944994d1d50000000511dd0000000000000000011000
000000000000000000dd111515000000000000000000511d1d00000000d11150500505151005051d1d01100110dd11500000511d1d0000000000000000000000
000000000000000000d1d150500000000000000000000511dd00000000dd11151551511115515111dd00000000d1d11500000511dd0000000000000000000001
000000000000000000dd150000000000000000000000005d1d00000000d1d1d1d1d1d1d1d111111d1d00000000dd11500000005d1d0000000000000000000000
000000000000335000d1d150000000001000000010000511dd00000000dd1d1d1d1d1d1d1dd1d1d1dd00000000d1d11500000511dd0000000000000000001000
000000000003555300dd150000000000000000000000005d1d000000000dddddddddddddddddddddd000000000dd15000000005d1d0000000000000000000000
00000000000ddddddd000000000000000000000000000051dd0000000000000000500500500000000000000000d1d50000000051dd0000000000000000000000
0000000000dd1d1d1d01100000000000000110000000511d1d0000000000000000550600000000000000000000dd11500000511d1d0110000000000000000000
0000000000d1d11111011000000000000001100000000511dd0000000000000000605500000000000000000000d1d50000000511dd0110000000000000000000
0000000000dd11151500000000000000000000000000511d1d0000000000000000600500000000000000000000dd11500000511d1d0000000000000000000000
0000000000d1d15050000001000000000000000100000511dd0000000000000000000600000000000000000000d1d11500000511dd0000010000000000000000
0000000000dd15000000000000000000000000000000005d1d0000000000000000000600000000000000000000dd11500000005d1d0000000000000000000000
0000500000d1d15000001000000000000000100000000511dd0000000000335000000600000000000000335000d1d11500000511dd0010000000000000000000
0005500500dd15000000000000000000000000000000005d1d0000000003555300000000000000000003555300dd15000000005d1d0000000000000000000000
ddddddddddd1d50000000000000000000000000000000051dddddddddddddddddddddddddddddddddddddddddddddddddd00000000dddddddddddddddddddddd
d1d1d1d1d1dd11500000000000000001000000010000511d1dd1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d100000000d1d1d1d1d1d1d1d1d1d1d1
1d1d1d1d1dd1d50000000000000000000000000000000511dd1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d000000001d1d1d1d1d1d1d1d1d1d1d
1551111515dd11500000000000000000000000000000511d1d511115155111151551111515511115155111151551111515000000005111151551111515511115
5001515050d1d11500000000000000000000000000000511dd015150500151505001515050015150500151505001515050000000000151505001515050015150
0005050000dd11500000000000000000000000000000005d1d050500000505000005050000050500000505000005050000000000000505000005050000050500
0000000000d1d11500000000000000001000000010000511dd000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000dd15000000000000000000000000000000005d1d000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000000010100000000000000000000000000000101000000000000000000000000000001010100004000000000000000000000000000000002010101010101010101010000000000000000000000000000000110100000000000000000000000000000004001808010014000000000000000000400008080
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
4b4b4747474b4b4b4b4b4b4b4b4b4b4b4b4b47474747474b4b4b4b4b4b4b4b4b717171717171000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4b460000004447474747474747474b4a4b4600005c0000484b4b4b4b4b4b4b4b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f467c6e6f000000007a0000005c444b4b467200000000484b4b4b4b4b4f4b4b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4946007e7f7c750000790000000000484b472c00000000484b4b4b474b4b4b4b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4b43404040400000006a000000720048464300007b000048494b4600484b4b4b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
460000000000000000000000000000484677000000004c484b4b4673484b4b4b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
46000000000000007b000000005b00484600000000002d4b4b4b4b454b4b4b4b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4600007374000000000000414542004846000000000000484b4b4b4b4b4b494b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
460000414200007c000000484b460048460000000c5b5b484b494b4b4b4b4b4b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4600004443000000007c0048494640484600000000404044474747474b4b4b4b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4600000000007b00000000484b4600484640000000000000006a007a484b4b4b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
460000000000004c007400484b46004846000000000000000000006a4447474b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4600000000000041454200485a46004846000000000000000000000000000048000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
460000000000414b4f464044474340484b4542005b007b005b000000756e6f48000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4b42000074414b4b4b460000000000484b4b46000c0000002b5b0000007e7f48000048000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4a4b4545454b494b4b4b45454545454b4b4b467070707000484240404145454b454545000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4b47474b4b4b4b4b4b4b4b4b4b4b4b4b4b4b4747474747474747474747474b4b4b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
467c0044474747474747474747474b494b4300000000000000000000000044474b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
466e6f00000000000000777a7700444b46000000000000000000000000756e6f4b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
467e7f75000000000000007a00000048460000004142000000005b5b00007e7f4b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
464040000000007c000000790000004846000000484b4200007b0c0c00004145000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
46000000007b0000007b006a007b00484640402d4747471c1c1c45420000484b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4600007200005b5b5b5b5b5b0000004846000000005c00005c004446002d484e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
46000000000041454545454200004048467b0000000000000000001b0000484b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4600000000004447474747430000004846000000000000000000001b2c00484b4b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4652537c0000000000000000000040484b1c4542005b00005b00001b0000484b4b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
46626300000000000000000000000048460044471c1c1c1c2c40401b402d48494b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
494542000000000000000000000040484600005c5c5c00000000001b005c484b4b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4b4b46000000007c00005b000000004846000000000000000000001b6c00484b4b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4b5a4600007b00007b002b5b7b000048460000000000005b5b0041467b00484b454542000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4b4b460000000000005b484200005b484b4545420000004145454b460000484b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4b4b43000000000000414b460000414b4b4b4b4b4545454b4b4b4b460000484b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00060000250412b021330013d00100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00040000191411f52124101211011c7000a6000a6000a600000000e300000000000000000000002c500000000000000000026000b600000000000000000000000000000000000000000000000000000000000000
000400000164003510150100f62012510127000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000016400350003600036200c500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010200002e0202f010320201f7501f730267202a710337100b120051203f10002700000000000000000000002a400000000000000000000000000000000000000000000000000000000000000000000000000000
010200000f713172200d6400f6300d3200f3100d3100f3200a2300c61000025000350005500044000230001000030000600005000040000200004000050000600007000060000500003000030000200001000040
__music__
00 01424344

