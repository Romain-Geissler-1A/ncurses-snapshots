------------------------------------------------------------------------------
--                                                                          --
--                       GNAT ncurses Binding Samples                       --
--                                                                          --
--                           Sample.Explanation                             --
--                                                                          --
--                                 B O D Y                                  --
--                                                                          --
--  Version 00.91                                                           --
--                                                                          --
--  The ncurses Ada95 binding is copyrighted 1996 by                        --
--  Juergen Pfeifer, Email: Juergen.Pfeifer@T-Online.de                     --
--                                                                          --
--  Permission is hereby granted to reproduce and distribute this           --
--  binding by any means and for any fee, whether alone or as part          --
--  of a larger distribution, in source or in binary form, PROVIDED         --
--  this notice is included with any such distribution, and is not          --
--  removed from any of its header files. Mention of ncurses and the        --
--  author of this binding in any applications linked with it is            --
--  highly appreciated.                                                     --
--                                                                          --
--  This binding comes AS IS with no warranty, implied or expressed.        --
------------------------------------------------------------------------------
--  Version Control
--  $Revision: 1.1 $
------------------------------------------------------------------------------
--  Poor mans help system. This scans a sequential file for key lines and
--  then reads the lines up to the next key. Those lines are presented in
--  a window as help or explanation.
--
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Unchecked_Deallocation;
with Terminal_Interface.Curses; use Terminal_Interface.Curses;
with Terminal_Interface.Curses.Panels; use Terminal_Interface.Curses.Panels;

with Sample.Keyboard_Handler; use Sample.Keyboard_Handler;
with Sample.Manifest; use Sample.Manifest;
with Sample.Function_Key_Setting; use Sample.Function_Key_Setting;
with Sample.Helpers; use Sample.Helpers;

package body Sample.Explanation is

   Help_Keys : constant String := "HELPKEYS";
   In_Help   : constant String := "INHELP";

   File_Name : String := "explain.txt";
   F : File_Type;

   type Help_Line;
   type Help_Line_Access is access Help_Line;
   pragma Controlled (Help_Line_Access);
   type String_Access is access String;
   pragma Controlled (String_Access);

   type Help_Line is
      record
         Prev, Next : Help_Line_Access;
         Line : String_Access;
      end record;

   procedure Explain (Key : in String;
                      Win : in Window);

   procedure Release_String is
     new Ada.Unchecked_Deallocation (String,
                                     String_Access);
   procedure Release_Help_Line is
     new Ada.Unchecked_Deallocation (Help_Line,
                                     Help_Line_Access);

   function Search (Key : String) return Help_Line_Access;
   procedure Release_Help (Root : in out Help_Line_Access);

   procedure Explain (Key : in String)
   is
   begin
      Explain (Key, Null_Window);
   end Explain;

   procedure Explain (Key : in String;
                      Win : in Window)
   is
      --  Retrieve the text associated with this key and display it in this
      --  window. If no window argument is passed, the routine will create
      --  a temporary window and use it.

      function Filter_Key return Real_Key_Code;
      procedure Unknown_Key;
      procedure Redo;
      procedure To_Window (C   : in out Help_Line_Access;
                          More : in out Boolean);

      Frame : Window := Null_Window;

      W : Window := Win;
      K : Real_Key_Code;
      P : Panel;

      Height   : Line_Count;
      Width    : Column_Count;
      Help     : Help_Line_Access := Search (Key);
      Current  : Help_Line_Access;
      Top_Line : Help_Line_Access;

      Has_More : Boolean;

      procedure Unknown_Key
      is
      begin
         Add (W, "Help message with ID ");
         Add (W, Key);
         Add (W, " not found.");
         Add (W, Character'Val (10));
         Add (W, "Press the Function key labelled 'Quit' key to continue.");
      end Unknown_Key;

      procedure Redo
      is
         H : Help_Line_Access := Top_Line;
      begin
         if Top_Line /= null then
            for L in 0 .. (Height - 1) loop
               Add (W, L, 0, H.Line.all);
               exit when H.Next = null;
               H := H.Next;
            end loop;
         else
            Unknown_Key;
         end if;
      end Redo;

      function Filter_Key return Real_Key_Code
      is
         K : Real_Key_Code;
      begin
         loop
            K := Get_Key (W);
            if K in Special_Key_Code'Range then
               case K is
                  when HELP_CODE =>
                     if not Find_Context (In_Help) then
                        Push_Environment (In_Help, False);
                        Explain (In_Help, W);
                        Pop_Environment;
                        Redo;
                     end if;
                  when EXPLAIN_CODE =>
                     if not Find_Context (Help_Keys) then
                        Push_Environment (Help_Keys, False);
                        Explain (Help_Keys, W);
                        Pop_Environment;
                        Redo;
                     end if;
                  when others => exit;
               end case;
            else
               exit;
            end if;
         end loop;
         return K;
      end Filter_Key;

      procedure To_Window (C   : in out Help_Line_Access;
                          More : in out Boolean)
      is
         L : Line_Position := 0;
      begin
         loop
            Add (W, L, 0, C.Line.all);
            L := L + 1;
            exit when C.Next = null or else L = Height;
            C := C.Next;
         end loop;
         if C.Next /= null then
            pragma Assert (L = Height);
            More := True;
         else
            More := False;
         end if;
      end To_Window;

   begin
      if W = Null_Window then
         Push_Environment ("HELP");
         Default_Labels;
         Frame := New_Window (Lines - 2, Columns, 0, 0);
         Box (Frame);
         Window_Title (Frame, "Explanation");
         W := Derived_Window (Frame, Lines - 4, Columns - 2, 1, 1);
         Refresh_Without_Update (Frame);
         Get_Size (W, Height, Width);
         Set_Meta_Mode (W);
         Set_KeyPad_Mode (W);
         Allow_Scrolling (W, True);
         Set_Echo_Mode (False);
         P := Create (Frame);
         Top (P);
         Update_Panels;
      else
         Clear (W);
         Refresh_Without_Update (W);
      end if;

      Current := Help; Top_Line := Help;

      if null = Help then
         Unknown_Key;
         loop
            K := Filter_Key;
            exit when K = QUIT_CODE;
         end loop;
      else
         To_Window (Current, Has_More);
         if Has_More then
            --  This means there are more lines available, so we have to go
            --  into a scroll manager.
            loop
               K := Filter_Key;
               if K in Special_Key_Code'Range then
                  case K is
                     when Key_Cursor_Down =>
                        if Current.Next /= null then
                           Move_Cursor (W, Height - 1, 0);
                           Scroll (W, 1);
                           Current := Current.Next;
                           Top_Line := Top_Line.Next;
                           Add (W, Current.Line.all);
                        end if;
                     when Key_Cursor_Up =>
                        if Top_Line.Prev /= null then
                           Move_Cursor (W, 0, 0);
                           Scroll (W, -1);
                           Top_Line := Top_Line.Prev;
                           Current := Current.Prev;
                           Add (W, Top_Line.Line.all);
                        end if;
                     when QUIT_CODE => exit;
                        when others => null;
                  end case;
               end if;
            end loop;
         else
            loop
               K := Filter_Key;
               exit when K = QUIT_CODE;
            end loop;
         end if;
      end if;

      Clear (W);

      if Frame /= Null_Window then
         Clear (Frame);
         Delete (P);
         Delete (W);
         Delete (Frame);
         Pop_Environment;
      end if;

      Update_Panels;
      Update_Screen;

      Release_Help (Help);

   end Explain;

   function Search (Key : String) return Help_Line_Access
   is
      Last    : Natural;
      Buffer  : String (1 .. 256);
      Root    : Help_Line_Access := null;
      Current : Help_Line_Access;
      Tail    : Help_Line_Access := null;
      Save    : String_Access;

      function Next_Line return Boolean;

      function Next_Line return Boolean
      is
         H_End : constant String := "#END";
      begin
         Get_Line (F, Buffer, Last);
         if Last = H_End'Length and then H_End = Buffer (1 .. Last) then
            return False;
         else
            return True;
         end if;
      end Next_Line;
   begin
      Reset (F);
      Outer :
      loop
         exit when not Next_Line;
         if Last = (1 + Key'Length) and then Key = Buffer (2 .. Last)
           and then Buffer (1) = '#' then
            loop
               exit when not Next_Line;
               exit when Buffer (1) = '#';
               Current := new Help_Line'(null, null,
                                         new String'(Buffer (1 .. Last)));
               if Tail = null then
                  Release_Help (Root);
                  Root := Current;
               else
                  Tail.Next := Current;
                  Current.Prev := Tail;
               end if;
               Tail := Current;
            end loop;
            exit Outer;
         end if;
      end loop Outer;
      return Root;
   end Search;

   procedure Release_Help (Root : in out Help_Line_Access)
   is
      Next : Help_Line_Access;
   begin
      loop
         exit when Root = null;
         Next := Root.Next;
         Release_String (Root.Line);
         Release_Help_Line (Root);
         Root := Next;
      end loop;
   end Release_Help;

   procedure Explain_Context
   is
   begin
      Explain (Context);
   end Explain_Context;

   procedure Notepad (Key : in String)
   is
      H : constant Help_Line_Access := Search (Key);
      T : Help_Line_Access := H;
      N : Line_Count := 1;
      L : Line_Position := 0;
      W : Window;
      P : Panel;
   begin
      if H /= null then
         loop
            T := T.Next;
            exit when T = null;
            N := N + 1;
         end loop;
         W := New_Window (N + 2, Columns, Lines - N - 2, 0);
         Box (W);
         Window_Title (W, "Notepad");
         P := New_Panel (W);
         T := H;
         loop
            Add (W, L + 1, 1, T.Line.all);
            L := L + 1;
            T := T.Next;
            exit when T = null;
         end loop;
         T := H;
         Release_Help (T);
         Refresh_Without_Update (W);
         Notepad_To_Context (P);
      end if;
   end Notepad;

begin
   Open (F, In_File, File_Name);
end Sample.Explanation;
