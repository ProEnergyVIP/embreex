# rtcore_geometry.pxd wrapper

cimport cython
cimport numpy as np
from embreex cimport rtcore as rtc
from embreex cimport rtcore_scene as rtcs

cdef extern from "embree4/rtcore_geometry.h":
    # Define invalid geometry ID
    cdef unsigned int RTC_INVALID_GEOMETRY_ID
    
    # Define buffer types for Embree4
    cdef enum RTCBufferType:
        RTC_BUFFER_TYPE_INDEX
        RTC_BUFFER_TYPE_VERTEX
        RTC_BUFFER_TYPE_VERTEX_ATTRIBUTE
        RTC_BUFFER_TYPE_NORMAL
        RTC_BUFFER_TYPE_TANGENT
        RTC_BUFFER_TYPE_NORMAL_DERIVATIVE
        
    # Define buffer formats for Embree4
    cdef enum RTCFormat:
        RTC_FORMAT_UNDEFINED
        RTC_FORMAT_FLOAT
        RTC_FORMAT_FLOAT2
        RTC_FORMAT_FLOAT3
        RTC_FORMAT_FLOAT4
        RTC_FORMAT_FLOAT8
        RTC_FORMAT_FLOAT16
        RTC_FORMAT_UINT
        RTC_FORMAT_UINT2
        RTC_FORMAT_UINT3
        RTC_FORMAT_UINT4
        RTC_FORMAT_UCHAR
        RTC_FORMAT_UCHAR2
        RTC_FORMAT_UCHAR3
        RTC_FORMAT_UCHAR4

    # Define geometry types for Embree4
    cdef enum RTCGeometryType:
        RTC_GEOMETRY_TYPE_TRIANGLE
        RTC_GEOMETRY_TYPE_QUAD
        RTC_GEOMETRY_TYPE_GRID
        RTC_GEOMETRY_TYPE_SUBDIVISION
        RTC_GEOMETRY_TYPE_CURVE
        RTC_GEOMETRY_TYPE_POINT
        RTC_GEOMETRY_TYPE_USER
        RTC_GEOMETRY_TYPE_INSTANCE
        
    # Define build quality for Embree4
    cdef enum RTCBuildQuality:
        RTC_BUILD_QUALITY_LOW
        RTC_BUILD_QUALITY_MEDIUM
        RTC_BUILD_QUALITY_HIGH
        RTC_BUILD_QUALITY_REFIT
        
    # Define opaque types
    ctypedef void* RTCBuffer
    ctypedef void* RTCGeometry
    
    # New API functions
    RTCGeometry rtcNewGeometry(rtc.RTCDevice device, RTCGeometryType type)
    void rtcRetainGeometry(RTCGeometry geometry)
    void rtcReleaseGeometry(RTCGeometry geometry)
    void rtcCommitGeometry(RTCGeometry geometry)
    void rtcEnableGeometry(RTCGeometry geometry)
    void rtcDisableGeometry(RTCGeometry geometry)
    void rtcSetGeometryTimeStepCount(RTCGeometry geometry, unsigned int timeStepCount)
    void rtcSetGeometryVertexAttributeCount(RTCGeometry geometry, unsigned int vertexAttributeCount)
    void rtcSetGeometryMask(RTCGeometry geometry, unsigned int mask)
    void rtcSetGeometryBuildQuality(RTCGeometry geometry, RTCBuildQuality quality)
    void rtcSetGeometryBuffer(RTCGeometry geometry, RTCBufferType type, unsigned int slot, RTCFormat format, RTCBuffer buffer, size_t byteOffset, size_t byteStride, size_t itemCount)
    void rtcSetSharedGeometryBuffer(RTCGeometry geometry, RTCBufferType type, unsigned int slot, RTCFormat format, const void* ptr, size_t byteOffset, size_t byteStride, size_t itemCount)
    void* rtcSetNewGeometryBuffer(RTCGeometry geometry, RTCBufferType type, unsigned int slot, RTCFormat format, size_t byteStride, size_t itemCount)
    void* rtcGetGeometryBufferData(RTCGeometry geometry, RTCBufferType type, unsigned int slot)
    void rtcUpdateGeometryBuffer(RTCGeometry geometry, RTCBufferType type, unsigned int slot)
    void rtcSetGeometryUserData(RTCGeometry geometry, void* ptr)
    void* rtcGetGeometryUserData(RTCGeometry geometry)
    unsigned int rtcAttachGeometry(rtcs.RTCScene scene, RTCGeometry geometry)
