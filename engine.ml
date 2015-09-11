open Tsdl

type t = {
    window : Sdl.window;
    renderer : Sdl.renderer;
    cell_size : int;
    width : int;
    height : int
  }

let init w h title =
  match Sdl.init Sdl.Init.(video + events) with
  | `Error e -> Sdl.log "Init error: %s" e; exit 1
  | `Ok () ->
     match Sdl.create_window ~w:w ~h:h title Sdl.Window.windowed with
     | `Error e -> Sdl.log "Create window error: %s" e; exit 1
     | `Ok window ->
        let flgs = Sdl.Renderer.(accelerated + presentvsync) in
        match Sdl.create_renderer ~flags:flgs window with
        | `Error e -> Sdl.log "Create renderer error: %s" e; exit 1
        | `Ok renderer ->
           let cell_size = 10 in
           { window;
             renderer;
             cell_size;
             width = w / cell_size;
             height = h / cell_size
           }

let clear eng =
  let r = eng.renderer in
  Sdl.set_render_draw_color r 50 50 50 255 |> ignore;
  Sdl.render_clear r |> ignore

let draw_cell eng x y =
  let r = eng.renderer in
  let xc = x * eng.cell_size in
  let yc = y * eng.cell_size in
  let rect = Sdl.Rect.create xc yc (eng.cell_size+1) (eng.cell_size+1) in
  Sdl.set_render_draw_color r 150 150 200 255 |> ignore;
  Sdl.render_draw_rect r (Some rect) |> ignore;
  Sdl.render_draw_point r (xc+eng.cell_size) (yc+eng.cell_size) |> ignore

let quit eng =
  Sdl.destroy_renderer eng.renderer;
  Sdl.destroy_window eng.window;
  Sdl.quit ()

let event = Sdl.Event.create ()

let rec loop draw update click paused eng =
  begin
    while Sdl.poll_event (Some event) do
      match Sdl.Event.(enum (get event typ)) with
      | `Quit ->
         quit eng;
         exit 0
      | `Mouse_button_down ->
         let x = Sdl.Event.(get event mouse_button_x) in
         let y = Sdl.Event.(get event mouse_button_y) in
         click eng (x / eng.cell_size) (y / eng.cell_size)
      | `Key_down ->
         let k = Sdl.Event.(get event keyboard_keycode) in
         if k = Sdl.K.space then paused := not !paused
      | _ -> ()
    done
  end;
  if not !paused then update eng else Sdl.delay 100l;
  draw eng;
  Sdl.render_present eng.renderer;
  loop draw update click paused eng
