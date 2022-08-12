package gltftools.data;

import haxe.io.Bytes;

typedef GltfId = Int;

typedef GltfProperty = {
	@:optional var extensions:Extensions;
	@:optional var extras:Dynamic;
}

typedef GltfChildOfRootProperty = {
	>GltfProperty,
	@:optional var name:String;
}

abstract GltfAccessor<T>(Dynamic) to Dynamic {
	public inline function keys() return Reflect.fields(this);
	public inline function get(name:String) return Reflect.field(this, name);
}

typedef Accessor = {
	>GltfChildOfRootProperty,
	@:optional var bufferView:GltfId;
	@:optional var byteOffset:Int; // def: 0
	var componentType:ComponentType;
	@:optional var normalized:Bool;
	var count:Int;
	var type:AccessorType;
	@:optional var max:Array<Float>;
	@:optional var min:Array<Float>;
	@:optional var sparce:AccessorSparse;
}

typedef AccessorSparse = {
	>GltfProperty,
	var count:Int;
	var indices:AccessorSparseIndices;
	var values:AccessorSparseValues;
}

typedef AccessorSparseIndices = {
	>GltfProperty,
	var bufferView:GltfId;
	@:optional var byteOffset:Int;
	var componentType:ComponentType;
}

typedef AccessorSparseValues = {
	>GltfProperty,
	var bufferView:GltfId;
	@:optional var byteOffset:Int;
}

enum abstract ComponentType(Int) {
	
	var CTByte = 5120;
	var CTUnsignedByte = 5121;
	var CTShort = 5122;
	var CTUnsignedShort = 5123;
	// var CTInt;
	var CTUnsignedInt = 5125;
	var CTFloat = 5126;

	public inline function toInt():Int { return this; }

}

enum abstract AccessorType(String) {
	var Scalar = "SCALAR";
	var Vec2 = "VEC2";
	var Vec3 = "VEC3";
	var Vec4 = "VEC4";
	var Mat2 = "MAT2";
	var Mat3 = "MAT3";
	var Mat4 = "MAT4";

	public inline function toString():String { return this; }

}

typedef AnimationChannel = {
	>GltfProperty,
	var sampler:GltfId;
	var target:AnimationChannelTarget;
}

typedef AnimationChannelTarget = {
	>GltfProperty,
	@:optional var node:GltfId;
	var path:AnimationPath;
}

enum abstract AnimationPath(String) {
	var Translation = "translation";
	var Rotation = "rotation";
	var Scale = "scale";
	var Weights = "weights";
	
	public inline function toString():String { return this; }
}

typedef AnimationSampler = {
	>GltfProperty,
	var input:GltfId;
	@:optional var interpolation:AnimationInterpolation;
	var output:GltfId;
}

enum abstract AnimationInterpolation(String) {
	var Linear = "LINEAR";
	var Step = "STEP";
	var CubicSpline = "CUBICSPLINE";

	public inline function toString():String { return this; }
}

typedef Animation = {
	>GltfChildOfRootProperty,
	var channels:Array<AnimationChannel>;
	var samplers:Array<AnimationSampler>;
}

typedef Asset = {
	>GltfProperty,
	@:optional var copyright:String;
	@:optional var generator:String;
	var version:String;
	@:optional var minVersion:String;
}

typedef Buffer = {
	>GltfChildOfRootProperty,
	@:optional var uri:String;
	var byteLength:Int;
}

typedef BufferView = {
	>GltfChildOfRootProperty,
	var buffer:GltfId;
	@:optional var byteOffset:Int;
	var byteLength:Int;
	@:optional var byteStride:Int;
	@:optional var target:BufferTarget;
}

enum abstract BufferTarget(Int) {
	var ArrayBuffer = 34962;
	var ElementArrayBuffer = 34963;

	public inline function toInt():Int { return this; }
}

typedef CameraOrthographic = {
	>GltfProperty,
	var xmag:Float;
	var ymag:Float;
	var zfar:Float;
	var znear:Float;
}

typedef CameraPerspective = {
	>GltfProperty,
	var aspectRatio:Float;
	var yfov:Float;
	var zfar:Float;
	var znear:Float;
}

typedef Camera = {
	>GltfChildOfRootProperty,
	@:optional var orthographic:CameraOrthographic;
	@:optional var perspective:CameraPerspective;
	var type:CameraType;
}

enum abstract CameraType(String) {
	var Perspective = "perspective";
	var Orthographic = "orthographic";

	public inline function toString():String { return this; }
}

// Extension = Dynamic
// Extras = Dynamic
typedef Gltf = {
	>GltfProperty,
	@:optional var extensionsUsed:Array<String>;
	@:optional var extensionsRequired:Array<String>;
	@:optional var accessors:Array<Accessor>;
	@:optional var animations:Array<Animation>;
	var asset:Asset;
	@:optional var buffers:Array<Buffer>;
	@:optional var bufferViews:Array<BufferView>;
	@:optional var cameras:Array<Camera>;
	@:optional var images:Array<Image>;
	@:optional var materials:Array<Material>;
	@:optional var meshes:Array<Mesh>;
	@:optional var nodes:Array<Node>;
	@:optional var samplers:Array<Sampler>;
	@:optional var scene:GltfId;
	@:optional var scenes:Array<Scene>;
	@:optional var skins:Array<Skin>;
	@:optional var textures:Array<Texture>;
}

typedef Image = {
	>GltfChildOfRootProperty,
	@:optional var uri:String;
	@:optional var mimeType:ImageMimeType;
	@:optional var bufferView:GltfId;
}

enum abstract ImageMimeType(String) {
	var ImageJpeg = "image/jpeg";
	var ImagePng = "image/png";

	public inline function toString():String { return this; }
}


typedef TextureInfo = {
	>GltfProperty,
	var index:GltfId;
	@:optional var texCoord:Int;
}

typedef MaterialNormalTextureInfo = {
	>TextureInfo,
	@:optional var scale:Float;
}

typedef MaterialOcclusionTextureInfo = {
	>TextureInfo,
	@:optional var strength:Float;
}

typedef MaterialMetalicRoughness = {
	>GltfProperty,
	@:optional var baseColorFactor:Array<Float>;
	@:optional var baseColorTexture:TextureInfo;
	@:optional var metallicFactor:Float;
	@:optional var roughnessFactor:Float;
	@:optional var metallicRoughnessTexture:TextureInfo;
}

typedef Material = {
	>GltfChildOfRootProperty,
	@:optional var pbrMetallicRoughness:MaterialMetalicRoughness;
	@:optional var normalTexture:MaterialNormalTextureInfo;
	@:optional var occlusionTexture:MaterialOcclusionTextureInfo;
	@:optional var emissiveTexture:TextureInfo;
	@:optional var emissiveFactor:Array<Float>;
	@:optional var alphaMode:MaterialAlphaMode;
	@:optional var alphaCutoff:Float;
	@:optional var doubleSided:Bool;
}

enum abstract MaterialAlphaMode(String) {
	var Opaque = "OPAQUE";
	var Mask = "MASK";
	var Blend = "BLEND";

	public inline function toString():String { return this; }
}

typedef MeshPrimitive = {
	>GltfProperty,
	var attributes:GltfAccessor<GltfId>;
	@:optional var indices:GltfId;
	@:optional var material:GltfId;
	@:optional var mode:MeshPrimitiveMode;
	@:optional var targets:Array<MeshPrimitiveTarget>;
}

enum abstract MeshPrimitiveMode(Int) {
	var Points = 0;
	var Lines;
	var LineLoop;
	var LineStrip;
	var Triangles;
	var TriangleStrip;
	var TriangleFan;

	public inline function toInt():Int { return this; }
}

typedef MeshPrimitiveTarget = {
	var POSITION:GltfId;
	var NORMAL:GltfId;
	var TANGENT:GltfId;
}

typedef Mesh = {
	>GltfChildOfRootProperty,
	var primitives:Array<MeshPrimitive>;
	@:optional var weights:Array<Float>;
}

typedef Node = {
	>GltfChildOfRootProperty,
	@:optional var camera:GltfId;
	@:optional var children:Array<GltfId>;
	@:optional var skin:GltfId;
	@:optional var matrix:Array<Float>;
	@:optional var mesh:GltfId;
	@:optional var rotation:Array<Float>;
	@:optional var scale:Array<Float>;
	@:optional var translation:Array<Float>;
	@:optional var weights:Array<Float>;
}

typedef Sampler = {
	>GltfChildOfRootProperty,
	@:optional var magFilter:SamplerFilterMode;
	@:optional var minFilter:SamplerFilterMode;
	@:optional var wrapS:SamplerWrapMode;
	@:optional var wrapT:SamplerWrapMode;
}

enum abstract SamplerFilterMode(Int) {
	var Nearest = 9728;
	var Linear = 9729;
	var NearestMipmapNearest = 9984;
	var LinearMipmapNearest = 9985;
	var NearestMipmapLinear = 9986;
	var LinearMipmapLinear = 9987;

	public inline function toInt():Int { return this; }
}

enum abstract SamplerWrapMode(Int) {
	var ClampToEdge = 33071;
	var MirroredRepeat = 33648;
	var Repeat = 10497;

	public inline function toInt():Int { return this; }
}

typedef Scene = {
	>GltfChildOfRootProperty,
	@:optional var nodes:Array<GltfId>;
}

typedef Skin = {
	>GltfChildOfRootProperty,
	@:optional var inverseBindMatrices:GltfId;
	@:optional var skeleton:GltfId;
	var joints:Array<GltfId>;
}

typedef Texture = {
	>GltfChildOfRootProperty,
	var sampler:GltfId;
	var source:GltfId;
}

// Extensions
typedef Extensions = {
	>GltfProperty,
	@:optional var KHR_materials_pbrSpecularGlossiness:MaterialSpecularGlossinessExt;
	@:optional var KHR_materials_clearcoat:MaterialClearCoatExt;
	@:optional var KHR_materials_sheen:MaterialSheenExt;
	@:optional var KHR_draco_mesh_compression:DracoMeshCompressionExt;
}

typedef MaterialSpecularGlossinessExt = {
	>GltfProperty,
	@:optional var diffuseFactor:Array<Float>;
	@:optional var diffuseTexture:TextureInfo;
	@:optional var specularFactor:Array<Float>;
	@:optional var glossinessFactor:Array<Float>;
	@:optional var specularGlossinessTexture:TextureInfo;
}

typedef MaterialClearCoatExt = {
	>GltfProperty,
	@:optional var clearcoatFactor:Float;
	@:optional var clearcoatTexture:TextureInfo;
	@:optional var clearcoatRoughnessFactor:Float;
	@:optional var clearcoatRoughnessTexture:TextureInfo;
	@:optional var clearcoatNormalTexture:MaterialNormalTextureInfo;
}

typedef MaterialSheenExt = {
	>GltfProperty,
	@:optional var sheenColorFactor:Array<Float>;
	@:optional var sheenRoughnessFactor:Float;
	@:optional var sheenTexture:TextureInfo;
}

typedef DracoMeshCompressionExt = {
	>GltfProperty,
	var bufferView:GltfId;
	var attributes:GltfAccessor<GltfId>;
}

typedef GltfContainer = {
	var header:Gltf;
	var buffers:Array<haxe.io.Bytes>;
}

typedef BytePointer = {
	var pos:Int;
}

class GLTFData {
}
