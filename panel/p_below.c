
/***************************************************************************
*                            COPYRIGHT NOTICE                              *
****************************************************************************
*                     panels is copyright (C) 1995                         *
*                          Zeyd M. Ben-Halim                               *
*                          zmbenhal@netcom.com                             *
*                          Eric S. Raymond                                 *
*                          esr@snark.thyrsus.com                           *
*                                                                          *
*	      All praise to the original author, Warren Tucker.            *
*                                                                          *
*        Permission is hereby granted to reproduce and distribute panels   *
*        by any means and for any fee, whether alone or as part of a       *
*        larger distribution, in source or in binary form, PROVIDED        *
*        this notice is included with any such distribution, and is not    *
*        removed from any of its header files. Mention of panels in any    *
*        applications linked with it is highly appreciated.                *
*                                                                          *
*        panels comes AS IS with no warranty, implied or expressed.        *
*                                                                          *
***************************************************************************/

/* p_below.c
 */
#include "panel.priv.h"

MODULE_ID("$Id: p_below.c,v 1.1 1997/10/12 13:16:22 juergen Exp $")

PANEL*
panel_below(const PANEL *pan)
{
  if(!pan)
    {
      /* if top and bottom are equal, we have no or only the pseudo panel */
      return(_nc_top_panel==_nc_bottom_panel ? (PANEL*)0 : _nc_top_panel);
    }
  else
    {
      /* we must not return the pseudo panel */
      return(pan->below==_nc_bottom_panel ? (PANEL*) 0 : pan->below);
    }
}