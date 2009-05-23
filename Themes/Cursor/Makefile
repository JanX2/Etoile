cursors: outputdir left_ptr xterm crosshair hand1 bottom_side left_side sb_h_double_arrow right_side top_side sb_v_double_arrow watch
	cp Source/index.theme Etoile/
	@echo Done building cursor.
install:
	cp -r Etoile /usr/share/icons
outputdir:
	mkdir -p Etoile/cursors
%:
	xcursorgen -p Source Source/$@.conf Etoile/cursors/$@
clean:
	rm -fdr Etoile
