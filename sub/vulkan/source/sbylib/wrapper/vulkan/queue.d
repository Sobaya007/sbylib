module sbylib.wrapper.vulkan.queue;

import erupted;
import sbylib.wrapper.vulkan.commandbuffer;
import sbylib.wrapper.vulkan.device;
import sbylib.wrapper.vulkan.enums;
import sbylib.wrapper.vulkan.fence;
import sbylib.wrapper.vulkan.swapchain;
import sbylib.wrapper.vulkan.util;

class Queue {

    /*
       1. Wait all `waitSemaphores` at each corresponding stage specified by `waitDstStageMask`
       2. Execute `commandBuffers`
       3. Signal all `signalSemaphores`
     */
    static struct SubmitInfo {
        @vkProp("pWaitSemaphores", "waitSemaphoreCount") {
            const VkSemaphore[] waitSemaphores;
        }

        @vkProp("pWaitDstStageMask") {
            const VkPipelineStageFlags[] waitDstStageMask;
        }

        @vkProp("pCommandBuffers", "commandBufferCount") {
            const CommandBuffer[] commandBuffers;
        }

        @vkProp("pSignalSemaphores", "signalSemaphoreCount") {
            const VkSemaphore[] signalSemaphores;
        }

        const mixin VkTo!(VkSubmitInfo);
    }

    static struct PresentInfo {
        @vkProp("pWaitSemaphores", "waitSemaphoreCount") {
            const VkSemaphore[] waitSemaphores;
        }

        @vkProp("pSwapchains", "swapchainCount") {
            const Swapchain[] swapchains;
        }

        @vkProp("pImageIndices") {
            const uint[] imageIndices;
        }

        @vkProp("pResults") {
            VkResult[] results;
        }

        invariant(swapchains.length == imageIndices.length);
        invariant(results is null || swapchains.length == results.length);

        mixin VkTo!(VkPresentInfoKHR);
    }

    private Device device;
    package VkQueue queue;

    mixin ImplNameSetter!(device, queue, DebugReportObjectType.Queue);

    package this(Device device, VkQueue queue) {
        this.device = device;
        this.queue = queue;
    }

    void submit(uint N)(SubmitInfo[N] _info, Fence _fence) {
        VkFence fence;
        if (_fence)
            fence = _fence.fence;

        VkSubmitInfo[N] info;
        static foreach (i; 0 .. N)
            info[i] = _info[i].vkTo();

        enforceVK(vkQueueSubmit(queue, N, info.ptr, fence));
    }

    void waitIdle() {
        enforceVK(vkQueueWaitIdle(queue));
    }

    void present(PresentInfo _info) {
        auto info = _info.vkTo();
        enforceVK(vkQueuePresentKHR(queue, &info));
    }

    mixin VkTo!(VkQueue);
}
