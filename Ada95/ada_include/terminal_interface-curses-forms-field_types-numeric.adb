------------------------------------------------------------------------------
--                                                                          --
--                           GNAT ncurses Binding                           --
--                                                                          --
--            Terminal_Interface.Curses.Forms.Field_Types.Numeric           --
--                                                                          --
--                                 B O D Y                                  --
--                                                                          --
--  Version 00.93                                                           --
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
--  Version Control:
--  $Revision: 1.1 $
------------------------------------------------------------------------------
with Interfaces.C;
with Terminal_Interface.Curses.Aux; use Terminal_Interface.Curses.Aux;

package body Terminal_Interface.Curses.Forms.Field_Types.Numeric is

   use type Interfaces.C.Int;

   procedure Set_Field_Type (Fld : in Field;
                             Typ : in Numeric_Field)
   is
      type Double is new Interfaces.C.double;

   C_Numeric_Field_Type : C_Field_Type;
   pragma Import (C, C_Numeric_Field_Type, "TYPE_NUMERIC");

   function Set_Fld_Type (F    : Field := Fld;
                          Cft  : C_Field_Type := C_Numeric_Field_Type;
                          Arg1 : C_Int;
                          Arg2 : Double;
                          Arg3 : Double) return C_Int;
   pragma Import (C, Set_Fld_Type, "set_field_type");

   Res : Eti_Error;
   begin
      Res := Set_Fld_Type (Arg1 => C_Int (Typ.Precision),
                           Arg2 => Double (Typ.Lower_Limit),
                           Arg3 => Double (Typ.Upper_Limit));
      if Res /= E_Ok then
         Eti_Exception (Res);
      end if;
      Wrap_Builtin (Fld, Typ);
   end Set_Field_Type;

end Terminal_Interface.Curses.Forms.Field_Types.Numeric;