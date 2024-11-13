struct Global {
  mut modes : Bool
  mut scene : UInt
  mut count : UInt64
  score : Array[UInt64]
}

const PLAYER_SIZE = 40
const BAN_WIDTH = 20
const BAN_HIGH = 4
const BALL_SIZE = 4

struct Player {
  mut x: Int
  mut nx : Int
  mut y: Int
  mut ny: Int
  mut f: Int
  mut p: @wasm4.GamePad
}

let global : Global = {scene : 1, modes : false, count : 0, score : [0, 0]}
let player : Array[Player] = [
  {x : 80, nx : 0, y : 160-PLAYER_SIZE/2, ny : 0, f : 3, p : @wasm4.get_gamepad(index=1)},
  {x : 80, nx : 0, y : PLAYER_SIZE/2, ny : 0, f : 1, p : @wasm4.get_gamepad(index=2)},
  {x : 80, nx : 1, y : 80, ny : 1, f : 0, p : @wasm4.get_gamepad(index=3)}
]

pub fn start() -> Unit {
  @wasm4.set_palette(1, @wasm4.rgb(0x86c06c))
  @wasm4.set_palette(2, @wasm4.rgb(0xe0f8cf))
}

pub fn update() -> Unit {
  global.count += 1
  input()
  screen()
}

fn screen() -> Unit {
  if global.scene == 1 {
    @wasm4.set_draw_colors(4, index=1)
    @wasm4.text("Sci-fi Ball", 35, 40)
    if global.modes {
      @wasm4.set_draw_colors(3, index=1)
    }
    @wasm4.text("VS 2P", 50, 100)
    if global.modes {
      @wasm4.set_draw_colors(4, index=1)
    } else {
      @wasm4.set_draw_colors(3, index=1)
    }
    @wasm4.text("VS CPU", 50, 120)
  } else if global.scene == 2 {
    for i in [0, 1] {
      @wasm4.set_draw_colors(0, index=1)
      @wasm4.set_draw_colors(2, index=2)
      @wasm4.rect(player[i].x-PLAYER_SIZE/2, player[i].y-PLAYER_SIZE/2, PLAYER_SIZE, PLAYER_SIZE)
      @wasm4.set_draw_colors(2, index=1)
      @wasm4.oval(player[i].x-BALL_SIZE/2, player[i].y-BALL_SIZE/2, BALL_SIZE, BALL_SIZE)
      @wasm4.set_draw_colors(3, index=1)
      @wasm4.set_draw_colors(4, index=2)
      if player[i].f == 1 {
        @wasm4.rect(player[i].x-BAN_WIDTH/2, player[i].y+PLAYER_SIZE/2-BAN_HIGH/2, BAN_WIDTH, BAN_HIGH)
      } else if player[i].f == 3 {
        @wasm4.rect(player[i].x-BAN_WIDTH/2, player[i].y-PLAYER_SIZE/2-BAN_HIGH/2, BAN_WIDTH, BAN_HIGH)
      } else if player[i].f == 2 {
        @wasm4.rect(player[i].x-PLAYER_SIZE/2-BAN_HIGH/2, player[i].y-BAN_WIDTH/2, BAN_HIGH, BAN_WIDTH)
      } else if player[i].f == 4 {
        @wasm4.rect(player[i].x+PLAYER_SIZE/2-BAN_HIGH, player[i].y-BAN_WIDTH/2, BAN_HIGH, BAN_WIDTH)
      }
    }
    @wasm4.oval(player[2].x-BALL_SIZE/2, player[2].y-BALL_SIZE/2, BALL_SIZE, BALL_SIZE)
  } else if global.scene >= 3 {
    @wasm4.set_draw_colors(4, index=1)
    @wasm4.set_draw_colors(0, index=2)
    @wasm4.text("\{global.score[1]}:\{global.score[0]}", 70, 75)
  }
}

fn input() -> Unit {
  if global.scene == 1 {
    if @wasm4.get_gamepad(index=1).button_1 {
      global.scene = 2
    }
    if (@wasm4.get_gamepad(index=1).button_up && not(player[0].p.button_up)) ||
    (@wasm4.get_gamepad(index=1).button_down && not(player[0].p.button_down)) {
      global.modes = not(global.modes)
    }
  } else if global.scene == 2 {
    if (global.count & 1) == 0 {
      for i in [1U, 2U] {
        playerMove(i)
      }
    }
    for i in [1U, 2U] {
      playerFace(i)
    }
    calcMove()
    for i in [0, 1] {
      if (player[i].x -player[2].x).abs() < BALL_SIZE &&
      (player[i].y -player[2].y).abs() < BALL_SIZE {
        global.score[i] += 1
        global.scene = 3
        global.scene += i.reinterpret_as_uint()
        global.count = 0
        @wasm4.tone(
          (440, 0),
          @wasm4.ADSR::new(60),
          @wasm4.ADSRVolume::new(100),
          @wasm4.ToneFlag::new()
        )
      }
    }
  } else if global.scene >= 3 {
    if (global.count > 180) {
      if global.scene == 4 {
        blablabla()
      } else {
        blablabla(b=true)
      }
      global.scene = 2
    }
  }
  for i in [0, 1] {
    player[i].nx = 0
    player[i].ny = 0
    player[i].p = @wasm4.get_gamepad(index=(i+1).reinterpret_as_uint())
  }
}

fn playerMove(index : UInt) -> Unit {
  if global.modes && index == 2U {
    if (player[2].x-player[1].x).abs() < PLAYER_SIZE/2 &&
    (player[2].y-player[1].y).abs() < PLAYER_SIZE/2 {
      let (nx, ny) = getAwayornot(player[2])
      player[1].nx = nx
      player[1].ny = ny
    } else if (player[2].x-player[1].x).abs() < PLAYER_SIZE &&
    (player[2].y-player[1].y).abs() < PLAYER_SIZE {
      let (nx, ny) = getAwayornot(player[2], b=-1)
      player[1].nx = nx
      player[1].ny = ny
    } else if (player[0].x-player[1].x).abs() < PLAYER_SIZE/2 ||
    (player[0].y-player[1].y).abs() < PLAYER_SIZE/2 {
      let (nx, ny) = getAwayornot(player[0])
      player[1].nx = nx
      player[1].ny = ny
    } else {
      let (nx, ny) = getAwayornot(player[0], b=-1)
      player[1].nx = nx
      player[1].ny = ny
    }
  } else {
    if @wasm4.get_gamepad(~index).button_down {
      player[(index-1).reinterpret_as_int()].ny += 1
    }
    if @wasm4.get_gamepad(~index).button_up {
      player[(index-1).reinterpret_as_int()].ny -= 1
    }
    if @wasm4.get_gamepad(~index).button_left {
      player[(index-1).reinterpret_as_int()].nx -= 1
    }
    if @wasm4.get_gamepad(~index).button_right {
      player[(index-1).reinterpret_as_int()].nx += 1
    }
  }
}

fn playerFace(index : UInt) -> Unit {
  if global.modes && index == 2U {
    if (player[1].x-player[2].x).abs() < (player[1].y-player[2].y).abs() {
      if player[2].y > player[1].y {
        player[1].f = 1
      } else {
        player[1].f = 3
      }
    } else {
      if player[2].x > player[1].x {
        player[1].f = 4
      } else {
        player[1].f = 2
      }
    }
  } else {  
    if @wasm4.get_gamepad(~index).button_1 && 
    not(player[(index-1).reinterpret_as_int()].p.button_1) {
      player[(index-1).reinterpret_as_int()].f -= 1
      if player[(index-1).reinterpret_as_int()].f < 1 {
        player[(index-1).reinterpret_as_int()].f = 4
      }
    }
    if @wasm4.get_gamepad(~index).button_2 && 
    not(player[(index-1).reinterpret_as_int()].p.button_2) {
      player[(index-1).reinterpret_as_int()].f += 1
      if player[(index-1).reinterpret_as_int()].f > 4 {
        player[(index-1).reinterpret_as_int()].f = 1
      }
    }
  }
}

fn calcMove() -> Unit {
  for p in [(0, 1), (1, 0)] {
    let a = player[p.0].x + player[p.0].nx
    if a + PLAYER_SIZE/2 > 160 || a - PLAYER_SIZE/2 < 0 ||
    ((player[p.0].y - player[p.1].y).abs() < PLAYER_SIZE &&
    (a - player[p.1].x).abs() < PLAYER_SIZE) {
      player[p.0].nx = 0
    }
    let a = player[p.0].y + player[p.0].ny
    if a + PLAYER_SIZE/2 > 160 || a - PLAYER_SIZE/2 < 0 ||
    ((player[p.0].x - player[p.1].x).abs() < PLAYER_SIZE &&
    (a - player[p.1].y).abs() < PLAYER_SIZE) {
      player[p.0].ny = 0
    }
  }
  let a = player[2].x + player[2].nx
  if a + BALL_SIZE/2 > 160 || a - BALL_SIZE/2 < 0 ||
  ballHitv(0, a) || ballHitv(1, a) {
    player[2].nx *= -1
  }
  let a = player[2].y + player[2].ny
  if a + BALL_SIZE/2 > 160 || a - BALL_SIZE/2 < 0 ||
  ballHith(0, a) || ballHith(1, a) {
    player[2].ny *= -1
  }
  for i in [0, 1, 2] {
    player[i].x += player[i].nx
    player[i].y += player[i].ny
  }
}

fn ballHitv(i : Int, a : Int) -> Bool {
  if (player[2].y-player[i].y).abs() < (BALL_SIZE+BAN_WIDTH)/2 &&
  (player[i].f == 2 && ((player[i].x-PLAYER_SIZE/2)-a).abs() < BALL_SIZE ||
  player[i].f == 4 && ((player[i].x+PLAYER_SIZE/2)-a).abs() < BALL_SIZE ) {
    return true
  } else {
    return false
  }
}

fn ballHith(i : Int, a : Int) -> Bool {
  if (player[2].x-player[i].x).abs() < (BALL_SIZE+BAN_WIDTH)/2 &&
  (player[i].f == 1 && ((player[i].y+PLAYER_SIZE/2)-a).abs() < BALL_SIZE ||
  player[i].f == 3 && ((player[i].y-PLAYER_SIZE/2)-a).abs() < BALL_SIZE ) {
    return true
  } else {
    return false
  }
}

fn blablabla(~b : Bool = false) -> Unit {
  player[0]={x : 80, nx : 0, y : 160-PLAYER_SIZE/2, ny : 0, f : 3, p : @wasm4.get_gamepad(index=1)}
  player[1]={x : 80, nx : 0, y : PLAYER_SIZE/2, ny : 0, f : 1, p : @wasm4.get_gamepad(index=2)}
  player[2]={x : 80, nx : 1, y : 80, ny : 1, f : 0, p : @wasm4.get_gamepad(index=3)}
  if b {
    player[2].ny = -1
  }
}

fn getAwayornot(pp : Player, ~b : Int = 1) -> (Int, Int) {
  let mut x = 0
  let mut y = 0
  if player[1].x < pp.x {
    x -= 1
  } else {
    x += 1
  }
  if player[1].y < pp.y {
    y -= 1
  } else {
    y += 1
  }
  let (x, y) = (x*b, y*b)
  (x, y)
}
