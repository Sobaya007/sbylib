module sbylib.graphics.camera.camera;

import sbylib.math;
import sbylib.graphics.util : ImplPos, ImplRot, ImplViewMatrix;

abstract class Camera {

    abstract mat4 projectionMatrix();

    mixin ImplPos;
    mixin ImplRot;
    mixin ImplViewMatrix;

    void capture(Entity)(Entity e) 
        if (__traits(hasMember, Entity, "viewMatrix") && is(typeof(Entity.init.viewMatrix = mat4.identity))
         && __traits(hasMember, Entity, "projectionMatrix") && is(typeof(Entity.init.projectionMatrix = mat4.identity)))
    {
        e.viewMatrix = this.viewMatrix;
        e.projectionMatrix = this.projectionMatrix;
        e.render();
    }
}
