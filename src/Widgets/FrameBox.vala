/* Development helper class
 *
 * Wraps GtkBox into GtkFrame so you can see the borders of the layout.
 */

public class FrameBox : Gtk.Frame {

    private Gtk.Box inner;

    public FrameBox (Gtk.Orientation orientation, int spacing, string label = "") {
        Object (
            label: label
        );

        inner = new Gtk.Box (orientation, spacing);
        add(inner);
    }

    public Gtk.BaselinePosition get_baseline_position () {
        return inner.get_baseline_position ();
    }
    
    public unowned Gtk.Widget? get_center_widget () {
        return inner.get_center_widget ();
    }
    
    public bool get_homogeneous () {
        return inner.get_homogeneous ();
    }
    
    public int get_spacing () {
        return inner.get_spacing ();
    }
    
    public void pack_end (Gtk.Widget child, bool expand = true, bool fill = true, uint padding = 0) {
        inner.pack_end (child, expand, fill, padding);
    }
    
    public void pack_start (Gtk.Widget child, bool expand = true, bool fill = true, uint padding = 0) {
        inner.pack_start (child, expand, fill, padding);
    }
    
    public void query_child_packing (Gtk.Widget child, out bool expand, out bool fill, out uint padding, out Gtk.PackType pack_type) {
        inner.query_child_packing (child, out expand, out fill, out padding, out pack_type);
    }
    
    public void reorder_child (Gtk.Widget child, int position) {
        inner.reorder_child (child, position);
    }
    
    public void set_baseline_position (Gtk.BaselinePosition position) {
        inner.set_baseline_position (position);
    }
    
    public void set_center_widget (Gtk.Widget? widget) {
        inner.set_center_widget (widget);
    }
    
    public void set_child_packing (Gtk.Widget child, bool expand, bool fill, uint padding, Gtk.PackType pack_type) {
        inner.set_child_packing (child, expand, fill, padding, pack_type);
    }
    
    public void set_homogeneous (bool homogeneous) {
        inner.set_homogeneous (homogeneous);
    }
    
    public void set_spacing (int spacing) {
        inner.set_spacing (spacing);
    }
}
