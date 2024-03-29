
(*
 * Copyright (C) 2007-2020 The laby team
 * You have permission to copy, modify, and redistribute under the
 * terms of the GPL-3.0. For full license terms, see gpl-3.0.txt.
 *)

let log = Log.make ["gfx"]

let conf =
  Conf.void
    (F.x "graphic interface configuration" [])

let conf_tilesize =
  Conf.int ~p:(conf#plug "tile-size") ~d:40
    (F.x "size of tiles in pixels" [])

let conf_playback_rate =
  Conf.float ~p:(conf#plug "playback-rate") ~d:2.0
    (F.x "number of iterations per second" [])

let conf_cue_rate =
  Conf.float ~p:(conf#plug "cue-rate") ~d:10.0
    (F.x "number of iterations per second in fast-forward/rewind mode" [])

let conf_source_style =
  Conf.string ~p:(conf#plug "source-style") ~d:"classic"
    (F.x "highlighting style to use for source code" [])

let conf_window =
  Conf.void ~p:(conf#plug "window")
    (F.x "initial window geometry" [])

let conf_window_width =
  Conf.int ~p:(conf_window#plug "width") ~d:800
    (F.x "width of window" [])

let conf_window_height =
  Conf.int ~p:(conf_window#plug "height") ~d:600
    (F.x "height of window" [])

exception Error of F.t

type ressources =
    {
      size : int;
      void_p : GdkPixbuf.pixbuf;
      exit_p : GdkPixbuf.pixbuf;
      wall_p : GdkPixbuf.pixbuf;
      rock_p : GdkPixbuf.pixbuf;
      web_p : GdkPixbuf.pixbuf;
      nrock_p : GdkPixbuf.pixbuf;
      nweb_p : GdkPixbuf.pixbuf;
      ant_n_p : GdkPixbuf.pixbuf;
      ant_e_p : GdkPixbuf.pixbuf;
      ant_s_p : GdkPixbuf.pixbuf;
      ant_w_p : GdkPixbuf.pixbuf;
    }

type controls =
    {
      window: GWindow.window;
      start_vbox: GPack.box;
      start_image: GMisc.image;
      main_hpaned: GPack.paned;
      menu_quit: GMenu.menu_item;
      menu_home: GMenu.menu_item;
      menu_level: GMenu.menu_item;
      menu_levels: GMenu.menu;
      button_start: GButton.button;
      button_prev: GButton.tool_button;
      button_next: GButton.tool_button;
      button_play: GButton.toggle_tool_button;
      button_backward: GButton.toggle_tool_button;
      button_forward: GButton.toggle_tool_button;
      button_execute: GButton.button;
      map_image: GMisc.image;
      interprets: GEdit.combo_box;
      view_prog: GSourceView3.source_view;
      view_help: GSourceView3.source_view;
      box_help: GPack.box;
      view_mesg: GText.view;
      view_title: GMisc.label;
      view_comment: GMisc.label;
    }

let messages l h m =
  if (l <= 0) && (Sys.os_type = "Win32" || not (Unix.isatty Unix.stdout)) then
    let message_type =
      match l with -4 | -3 | -2 -> `ERROR | -1 -> `WARNING | _ -> `INFO
    in
    let w =
      GWindow.message_dialog
	~title:("laby: " ^ Fd.render_raw h) ~buttons:GWindow.Buttons.ok
	~message:(Fd.render_raw m)
	~message_type ()
    in
    let _ = w#run () in w#destroy ()


let exception_handler e =
  let bt = Printexc.get_backtrace () in
  Run.error (
    F.x "exception: <exn>" [
      "exn", F.exn ~bt e;
    ]
  )

let gtk_init () =
  GtkSignal.user_handler := exception_handler;
  let _ = GtkMain.Main.init () in
  Run.report messages;
  (* work around messed up gtk/lablgtk *)
  Sys.catch_break false;
  begin match Sys.os_type with
  | "Unix" ->
      Sys.set_signal Sys.sigpipe (Sys.Signal_default);
      Sys.set_signal Sys.sigquit (Sys.Signal_default);
  | _ -> ()
  end;
  Sys.set_signal Sys.sigterm (Sys.Signal_default);
  let tile_size = max 5 conf_tilesize#get in
  let pix p =
    let file = Res.get ["tiles"; p ^ ".svg"] in
    begin try
      GdkPixbuf.from_file_at_size file tile_size tile_size
    with
    | GdkPixbuf.GdkPixbufError(GdkPixbuf.ERROR_UNKNOWN_TYPE, _) ->
	let file = Res.get ["tiles"; p ^ ".png"] in
	GdkPixbuf.from_file_at_size file tile_size tile_size
    end
  in
  {
    size = tile_size;
    void_p = pix "void";
    exit_p = pix "exit";
    wall_p = pix "wall";
    rock_p = pix "rock";
    web_p = pix "web";
    nrock_p = pix "nrock";
    nweb_p = pix "nweb";
    ant_n_p = pix "ant-n";
    ant_e_p = pix "ant-e";
    ant_s_p = pix "ant-s";
    ant_w_p = pix "ant-w";
  }

let draw_state state ressources (pixbuf : GdkPixbuf.pixbuf) =
  let size = ressources.size in
  let tile i j p =
    let px = size / 2 + i * size in
    let py = size / 2 + j * size in
    (* GdkPixbuf.copy_area ~dest:pixbuf ~dest_x:px ~dest_y:py p *)
    GdkPixbuf.composite ~dest:pixbuf ~alpha:255
      ~dest_x:px ~dest_y:py ~width:size ~height:size
      ~ofs_x:(float px) ~ofs_y:(float py) ~scale_x:1.0 ~scale_y:1.0 p
  in
  let i0, j0 = State.pos state in
  let disp_tile i j t =
    begin match t with
    | `Void -> tile i j ressources.void_p
    | `Exit -> if i <> i0 || j <> j0 then tile i j ressources.exit_p
    | `Wall -> tile i j ressources.wall_p
    | `Rock -> tile i j ressources.rock_p
    | `Web -> tile i j ressources.web_p
    | `NRock -> tile i j ressources.nrock_p
    | `NWeb -> tile i j ressources.nweb_p
    end
  in
  State.iter_map state disp_tile;
  begin match State.dir state with
  | `N -> tile i0 j0 ressources.ant_n_p
  | `E -> tile i0 j0 ressources.ant_e_p
  | `S -> tile i0 j0 ressources.ant_s_p
  | `W -> tile i0 j0 ressources.ant_w_p
  end;
  begin match State.carry state with
  | `Rock -> tile i0 j0 ressources.rock_p
  | `None -> ()
  end

let labeled_combo text packing strings =
  let box = GPack.hbox ~packing () in
  let _ = GMisc.label ~text ~xpad:5 ~ypad:8 ~packing:box#pack () in
  fst (GEdit.combo_box_text ~strings ~packing:box#add ())

let label packing =
  GMisc.label ~ypad:5 ~line_wrap:true ~packing ()

let label_txt text packing =
  ignore (GMisc.label ~text ~ypad:5 ~line_wrap:true ~packing ())

let label_menu = F.x "Menu" []
let label_level = F.x "Level" []
let label_welcome = F.x "Welcome to clc-laby v1.0 (12thJan2024), a programming game." []
let label_language = F.x "Language:" []
let label_prog = F.x "Program:" []
let label_mesg = F.x "Messages:" []
let label_help = F.x "Help:" []
let label_start = F.x "Start" []

let layout languages =
  let scrolled ?(vpolicy=`ALWAYS) packing =
    GBin.scrolled_window ~packing ~hpolicy:`AUTOMATIC ~vpolicy ()
  in
  let monofont = GPango.font_description_from_string "monospace" in
  let window = GWindow.window ~resizable:true () in
  let windowbox = GPack.vbox ~packing:window#add () in
  let menu_bar = GMenu.menu_bar ~packing:windowbox#pack () in
  let menu_levels = GMenu.menu () in
  let sub_main = GMenu.menu () in
  let menu_main = GMenu.menu_item ~label:(Fd.render_raw label_menu)
    ~packing:menu_bar#append () in
  let menu_level = GMenu.menu_item
    ~label:(Fd.render_raw label_level) ~packing:menu_bar#append () in
  let menu_fullscreen = GMenu.menu_item ~label:"Fullscreen"
    ~packing:sub_main#append () in
  let menu_unfullscreen = GMenu.menu_item ~label:"Leave Fullscreen"
    ~packing:sub_main#append ~show:false () in
  let menu_quit = GMenu.menu_item ~label:"Quit"
    ~packing:sub_main#append () in
  let menu_home = GMenu.menu_item ~label:"Home"
    ~packing:sub_main#append () in
  let fullscreen () =
    menu_fullscreen#misc#hide ();
    menu_unfullscreen#misc#show ();
    window#fullscreen ();
  in
  let unfullscreen () =
    menu_unfullscreen#misc#hide ();
    menu_fullscreen#misc#show ();
    window#unfullscreen ();
  in
  ignore (menu_fullscreen#connect#activate ~callback:fullscreen);
  ignore (menu_unfullscreen#connect#activate ~callback:unfullscreen);
  menu_level#set_submenu menu_levels;
  menu_main#set_submenu sub_main;
  let main_vbox = GPack.vbox ~packing:windowbox#add () in

  (* Start-up screen *)
  let start_vbox = GPack.vbox ~packing:main_vbox#add
    ~spacing:10 ~border_width:25 () in
  let start_image = GMisc.image ~packing:start_vbox#add () in
  let mstart_vbox = GPack.vbox ~packing:start_vbox#pack () in
  let _ = GMisc.label ~markup:(Fd.render_raw label_welcome)
    ~justify:`CENTER ~packing:mstart_vbox#pack () in
  let interprets =
    labeled_combo (Fd.render_raw label_language) mstart_vbox#pack languages
  in
  let button_start = GButton.button ~packing:mstart_vbox#pack
    ~label:(Fd.render_raw label_start) () in

  (* Game screen *)
  let hpaned = GPack.paned `HORIZONTAL ~packing:main_vbox#add () in
  let tile_size = max 5 conf_tilesize#get in
  hpaned#set_position (80 + 550 * tile_size / 40);
  let lvbox = GPack.vbox ~packing:hpaned#add1 () in
  let vpaned = GPack.paned `VERTICAL ~packing:hpaned#add () in
  vpaned#set_position 400;
  let view_title = label lvbox#pack in
  let view_comment = label lvbox#pack in
  let sw_laby = scrolled ~vpolicy:`AUTOMATIC lvbox#add in
  let box_help = GPack.vbox ~packing:lvbox#pack () in
  label_txt (Fd.render_raw label_help) box_help#pack;
  let sw_help = scrolled box_help#pack in
  let view_help =
    GSourceView3.source_view ~height:100 ~editable:false ~packing:sw_help#add ()
  in
  view_help#set_indent 1;
  view_help#misc#modify_font monofont;
  let rtvbox = GPack.vbox ~packing:vpaned#add1 () in
  label_txt (Fd.render_raw label_prog) rtvbox#pack;
  let sw_prog = scrolled rtvbox#add in
  let view_prog =
    GSourceView3.source_view
      ~auto_indent:true ~indent_width:2 ~insert_spaces_instead_of_tabs:true
      ~show_line_numbers:true ~packing:sw_prog#add ()
  in
  view_prog#set_indent 1;
  view_prog#misc#modify_font monofont;
  let bbox = GPack.hbox ~packing:rtvbox#pack () in
  let button_execute = GButton.button ~packing:bbox#pack ~stock:`EXECUTE () in
  let rbvbox = GPack.vbox ~packing:vpaned#add2 () in
  let toolbar = GButton.toolbar ~packing:bbox#pack () in
  let button stock = GButton.tool_button ~packing:toolbar#insert ~stock () in
  let tbutton stock =
    GButton.toggle_tool_button ~packing:toolbar#insert ~stock ()
  in
  let button_backward = tbutton `MEDIA_REWIND in
  let button_prev = button `GO_BACK in
  let button_play = tbutton `MEDIA_PLAY in
  let button_next = button `GO_FORWARD in
  let button_forward = tbutton `MEDIA_FORWARD in
  view_prog#misc#grab_focus ();
  label_txt (Fd.render_raw label_mesg) rbvbox#pack;
  let sw_mesg = scrolled rbvbox#add in
  let view_mesg = GText.view ~editable:false ~packing:sw_mesg#add  () in
  view_mesg#misc#modify_font monofont;
  let map_image = GMisc.image ~packing:sw_laby#add_with_viewport () in
  button_execute#set_focus_on_click false;
  {
    window = window;
    start_vbox = start_vbox;
    start_image = start_image;
    main_hpaned = hpaned;
    menu_quit = menu_quit; menu_home = menu_home;
    menu_level = menu_level; menu_levels = menu_levels;
    button_start = button_start;
    button_prev = button_prev; button_next = button_next;
    button_play = button_play;
    button_backward = button_backward;
    button_forward = button_forward;
    button_execute = button_execute;
    map_image = map_image;
    interprets = interprets;
    view_prog = view_prog; view_mesg = view_mesg;
    box_help = box_help; view_help = view_help;
    view_title = view_title; view_comment = view_comment;
  }

let make_pixbuf tile_size level =
  let sizex, sizey = Level.size level in
  let width, height = tile_size * (1 + sizex), tile_size * (1 + sizey) in
  GdkPixbuf.create ~width ~height ~has_alpha:true ()


let display_gtk ressources =

  let amods = Mod.pool () in
  let mods = List.filter (fun x -> x#check) amods in
  let language_list =
    List.sort (compare) (List.map (fun x -> x#name) mods)
  in
  let levels_list =
    List.sort (compare) (Res.get_list ~ext:"laby" ["levels"])
  in
  if mods = [] then Run.fatal (
    F.x "no mod is available among: <list>" [
      "list", F.v (List.map (fun x -> F.string x#name) amods);
    ]
  );

  let c = layout language_list in
  let level_load name =
    let l = Level.load (Res.get ["levels"; name]) in
    c.map_image#set_pixbuf (make_pixbuf ressources.size l); l
  in
  let syntaxd = Res.get ["syntax"] in
  let add_search_path m l = m#set_search_path (l @ m#search_path) in
  let ssm = GSourceView3.source_style_scheme_manager true in
  add_search_path ssm [syntaxd; Res.path [syntaxd; "styles"]];
  let style = ssm#style_scheme conf_source_style#get in
  c.view_prog#source_buffer#set_style_scheme style;
  c.view_help#source_buffer#set_style_scheme style;
  let slm = GSourceView3.source_language_manager false in
  add_search_path slm [syntaxd; Res.path [syntaxd; "language-specs"]];

  (* gui outputs *)
  let msg str =
    c.view_mesg#buffer#place_cursor c.view_mesg#buffer#end_iter;
    c.view_mesg#buffer#insert (str ^ "\n")
  in
  let f_msg m = msg (Fd.render_raw m) in
  let help h =
    begin match h with
    | None ->
	c.box_help#misc#hide ()
    | Some help ->
	c.view_help#buffer#set_text help;
	c.box_help#misc#show ()
    end
  in
  let draw image state =
    let p : GdkPixbuf.pixbuf = image#pixbuf in
    GdkPixbuf.fill p 0l;
    draw_state state ressources p;
    image#set_pixbuf p
  in

  (* game creation *)
  let command = Game.play msg help (draw c.map_image) in

  (* gui inputs *)
  let rid = ref None in
  let start_animation = ref (Level.generate Level.dummy) in
  let start_play () =
    c.start_vbox#misc#hide ();
    c.menu_quit#misc#hide ();
    begin match !rid with
      | None -> ()
      | Some id -> GMain.Timeout.remove id; rid := None
    end;
    rid := None;
    c.menu_home#misc#show ();
    c.menu_level#misc#show ();
    c.main_hpaned#misc#show ()

  in
  let exit_play () =
    c.main_hpaned#misc#hide ();
    c.menu_home#misc#hide ();
    c.menu_level#misc#hide ();
    let callback () =
      start_animation := State.random_walk !start_animation;
      draw c.start_image (!start_animation);
      true
    in
    let rate = conf_playback_rate#get in
    let ms = int_of_float (1000. /. rate) in
    rid := Some (GMain.Timeout.add ~ms ~callback);
    c.menu_quit#misc#show ();
    c.start_vbox#misc#show ()
  in
  let show_execute () = c.button_execute#set_relief `NORMAL in
  let hide_execute () = c.button_execute#set_relief `NONE in
  let ctrl_sensitive b =
    c.button_backward#misc#set_sensitive b;
    c.button_forward#misc#set_sensitive b;
    c.button_play#misc#set_sensitive b;
    c.button_prev#misc#set_sensitive b;
    c.button_next#misc#set_sensitive b;
  in
  let play_inactive () =
    c.button_forward#set_active false;
    c.button_backward#set_active false;
    c.button_play#set_active false
  in
  let clear () =
    c.view_mesg#buffer#set_text "";
    ctrl_sensitive false;
    show_execute ();
    play_inactive ();
  in
  let setupmod () =
    begin match
      try Some (List.nth language_list c.interprets#active)
      with _ -> None
    with
      | Some name ->
	 let lmod = List.find (fun x -> x#name = name) mods in
	 c.view_prog#buffer#set_text (command#chg_mod lmod);
	 let l = slm#language name in
	 if l = None then
	   log#warning (
	    F.x "cannot load syntax for <name> mod" [
	      "name", F.string name;
	    ]
	  );
	 c.view_prog#source_buffer#set_language l;
	 c.view_help#source_buffer#set_language l;
      | None -> ()
    end
  in
  let newmod () =
    command#chg_program (c.view_prog#buffer#get_text ());
    setupmod ();
    clear ()
  in
  let execute () =
    clear ();
    command#chg_program (c.view_prog#buffer#get_text ());
    begin match command#run with
    | true ->
	f_msg (F.h [F.s "——"; Say.good_start; F.s "——"]);
	ctrl_sensitive true
    | false ->
	f_msg (F.h [F.s "——"; Say.bad_start; F.s "——"]);
	ctrl_sensitive false
    end;
    hide_execute ();
  in
  let newlevel name =
    begin match List.mem name levels_list with
    | true ->
	let l = level_load name in
	c.view_title#set_text (Level.title l);
	c.view_comment#set_text (Level.comment l);
	command#chg_level l;
	clear ()
    | false -> ()
    end
  in
  let prev () = if not command#prev then play_inactive () in
  let next () = if not command#next then play_inactive () in
  let play =
    let rid = ref None in
    begin fun direction rate () ->
      begin match !rid with
      | None ->
	  let callback () =
	    begin match direction with
	    | `Forward -> next (); true
	    | `Backward -> prev (); true
	    end
	  in
          let ms = int_of_float (1000. /. rate) in
	  rid := Some (GMain.Timeout.add ~ms ~callback);
      | Some id ->
	  play_inactive ();
	  GMain.Timeout.remove id; rid := None
      end
    end
  in
  let destroy () =
    command#quit;
    c.window#destroy ();
    GMain.Main.quit ()
  in
  let altdestroy _ = destroy (); true in
  let smod = Mod.conf_selected#get in
  let select i m = if m = smod then c.interprets#set_active i in
  List.iteri select language_list;

  let group = ref None in
  let add_language l =
    let item = GMenu.radio_menu_item ?group:!group
      ~label:l ~packing:c.menu_levels#append () in
    if !group = None then group := Some (item#group);
    ignore (item#connect#activate ~callback:(fun () -> newlevel l))
  in
  List.iter add_language levels_list;

  (* declaring callbacks *)
  let play_cb = play `Forward conf_playback_rate#get in
  let forward_cb = play `Forward conf_cue_rate#get in
  let backward_cb = play `Backward conf_cue_rate#get in
  ignore (c.window#event#connect#delete ~callback:altdestroy);
  ignore (c.window#connect#destroy ~callback:destroy);
  ignore (c.button_start#connect#clicked ~callback:start_play);
  ignore (c.button_prev#connect#clicked ~callback:prev);
  ignore (c.button_next#connect#clicked ~callback:next);
  ignore (c.button_play#connect#toggled ~callback:play_cb);
  ignore (c.button_backward#connect#toggled ~callback:backward_cb);
  ignore (c.button_forward#connect#toggled ~callback:forward_cb);
  ignore (c.button_execute#connect#clicked ~callback:execute);
  ignore (c.interprets#connect#changed ~callback:newmod);
  ignore (c.view_prog#buffer#connect#changed ~callback:show_execute);
  ignore (c.menu_quit#connect#activate ~callback:destroy);
  ignore (c.menu_home#connect#activate ~callback:exit_play);
  (* now we must have everything up *)
  setupmod ();
  exit_play ();
  c.window#set_default_size conf_window_width#get conf_window_height#get;
  c.window#show ();
  if List.mem "0.laby" levels_list
  then newlevel "0.laby"
  else if levels_list <> [] then newlevel (List.hd levels_list);
  c.start_image#set_pixbuf (make_pixbuf ressources.size Level.dummy);
  draw c.start_image (!start_animation);
  ignore (GMain.Main.main ())

let run_gtk () =
  let ressources =
    begin try gtk_init () with
    | Gtk.Error m ->
	raise (
	  Error (
	    F.x "gtk error: <error>" ["error", F.q (F.string m)]
	  )
	)
    end
  in
  display_gtk ressources


