module sbylib.graphics.camera.perspectivecamera;

public import sbylib.math : Angle, mat4;
import sbylib.graphics.camera.camera : Camera;
import sbylib.graphics.util : ImplPos, ImplRot, ImplViewMatrix;

class PerspectiveCamera : Camera {

    float near, far, aspect;
    Angle fov;

    override mat4 projectionMatrix() {
        import sbylib.math : mat4;
        return mat4.perspective(aspect, fov, near, far);
    }

    static struct Builder {
        float near, far, aspect;
        Angle fov;
    
        PerspectiveCamera build() {
            auto result = new PerspectiveCamera;
            result.near = near;
            result.far = far;
            result.aspect = aspect;
            result.fov = fov;
            return result;
        }
    }
}
