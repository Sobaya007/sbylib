import std;
import erupted;
import sbylib.graphics;
import sbylib.event;
import sbylib.engine;
import sbylib.wrapper.assimp : PostProcessFlag;
import sbylib.wrapper.glfw;
import sbylib.wrapper.vulkan;
import sbylib.graphics.util.testcompute;

mixin(Register!(root));

void root(Project proj, ModuleContext context) {
    auto window = setupWindow(proj);
    auto camera = setupCamera(proj);

    auto cameraControl = context.pushResource(new CameraControl(window, camera));
    cameraControl.bind();

    VulkanContext.initialize("example app", VK_MAKE_VERSION(0,0,1), window);
    context.pushReleaseCallback({ VulkanContext.deinitialize(); });

    setupFloor(context, window, camera);
    setupBox(context, window, camera);

    with (TestCompute()) {
        context.pushReleaseCallback({ TestCompute.deinitialize(); });

        auto x = iota(256).map!(i => TestCompute.Data(vec3(i),vec3(i),i)).array;
        with (input) {
            len = 100;
            data[] = x[];
        }

        with (ComputeContext) {
            Queue.SubmitInfo submitInfo = {
                commandBuffers: [commandBuffer]
            };
            queue.submit([submitInfo], fence);
            Fence.wait([fence], true, ulong.max);
        }

        with (output) {
            assert(data == x);
        }
    }

    with (context()) {
        when(Frame(88)).then({
            StandardRenderPass(window).submitRender();
            GBufferRenderPass(window).submitRender();
        });
        when(KeyButton.Escape.pressed.on(window)).then({
            window.shouldClose = true;
        });
        when((Ctrl + KeyButton.KeyR).pressed.on(window)).then({
            proj.reloadAll();
        });
    }
}

private Window setupWindow(Project proj) {
    auto window = proj.get!Window("window");
    auto videoMode = Screen.getPrimaryScreen().currentVideoMode;
    window.pos = [0.pixel, 0.pixel];
    return window;
}

private Camera setupCamera(Project proj) {
    with (PerspectiveCamera.Builder()) {
        near = 0.1;
        far = 100;
        fov = 90.deg;
        aspect = 1;

        auto camera = build();
        camera.pos = vec3(0,0,3);
        proj["camera"] = cast(Camera)camera;

        return camera;
    }
}

private Floor setupFloor(ModuleContext context, Window window, Camera camera) {
    auto floor = new Floor(window, GeometryLibrary().buildPlane());
    context.pushResource(floor);
    with (floor) {
        pos = vec3(0,-2,0);
        rot = mat3.axisAngle(vec3(1,0,0), 90.deg);
        scale = vec3(10);
    }
    with (context()) {
        when(Frame).then({
            with (floor.vertexUniform) {
                worldMatrix = floor.worldMatrix;
                viewMatrix = camera.viewMatrix;
                projectionMatrix = camera.projectionMatrix;
            }
        });
    }

    with (floor.fragmentUniform) {
        tileSize = vec2(0.1f);
    }
    return floor;
}

class Floor {
    mixin ImplPos;
    mixin ImplRot;
    mixin ImplScale;
    mixin ImplWorldMatrix;
    mixin UseMaterial!(UnrealFloorMaterial);
}

private void setupBox(ModuleContext context, Window window, Camera camera) {
    void createFromGeometry(Geometry)(Geometry geom) {
        auto box = new Box(window, geom);
        context.pushResource(box);

        with (context()) {
            when(Frame).then({
                with (box.vertexUniform) {
                    worldMatrix = box.worldMatrix;
                    viewMatrix = camera.viewMatrix;
                    projectionMatrix = camera.projectionMatrix;
                }
            });
        }
    }

    void create(ModelNode node, mat4 transform) {
        transform = node.transformation * transform;
        foreach (mesh; node.meshes) {
            createFromGeometry(mesh.geom);
        }
        foreach (child; node.children) {
            create(child, transform);
        }
    }

    create(loadModel("resource/test.blend", PostProcessFlag.Triangulate), mat4.identity);
}

class Box {
    mixin ImplPos;
    mixin ImplRot;
    mixin ImplScale;
    mixin ImplWorldMatrix;
    mixin UseMaterial!(GBufferNormalMaterial);
}
