# ptable.sile

[![license](https://img.shields.io/github/license/Omikhleia/ptable.sile)](LICENSE)
[![Luarocks](https://img.shields.io/luarocks/v/Omikhleia/ptable.sile?label=Luarocks&logo=Lua)](https://luarocks.org/modules/Omikhleia/ptable.sile)

This package set for the [SILE](https://github.com/sile-typesetter/sile) typesetting
system provides struts, paragraph boxes (parbox), framed boxes (framebox) and
tables (ptable).

The two first are building blocks:

- In professional typesetting, a “strut” is a rule with no width but a certain
  height and depth, to help guaranteeing that an element has a certain minimal
  height and depth, e.g. in tabular environments or in boxes.
- A paragraph box (“parbox”) is an horizontal box (so technically an “hbox”)
  that contains, as its name implies, one or more paragraphs (so the displayed
  content is actually made of vertical glues and boxes)

Tables are what you would expect.

![tables](tables.png "Table examples")

As the name implies, framed boxes are horizontal content framed in a nice
box. The package offers various interesting options and goodies.

![framed boxes](framebox.png "Framed box examples")

## Installation

These packages require SILE v0.14 or upper.

Installation relies on the **luarocks** package manager.

To install the latest development version, you may use the provided “rockspec”:

```
luarocks --lua-version 5.4 install --server=https://luarocks.org/dev ptable.sile
```

(Adapt to your version of Lua, if need be, and refer to the SILE manual for more
detailed 3rd-party package installation information.)
