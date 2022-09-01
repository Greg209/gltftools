package gltftools;

import openfl.geom.Vector3D;
import gltftools.data.GLTFData;
import openfl.Vector;
import openfl.Vector;
import openfl.display.BitmapData;
import openfl.geom.Matrix3D;
import haxe.ds.ObjectMap;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.crypto.Base64;

#if away3d
import away3d.containers.ObjectContainer3D;
import away3d.core.base.Geometry;
import away3d.core.base.SubMesh;
import away3d.core.base.CompactSubGeometry;
import away3d.entities.Mesh;
import away3d.library.assets.Asset3DType;
import away3d.materials.ColorMaterial;
import away3d.materials.TextureMaterial;
import away3d.textures.BitmapTexture;
#end

typedef GLTFMesh = gltftools.data.Mesh;
typedef MinMax = {
    var min:Array<Float>;
    var max:Array<Float>;
}

typedef ImageFile = {
    var filename:String;
    var data:BytesBuffer;
    var index:Int;
}

enum BinaryData {
    EMBEDDED;
    EXTERNAL;
    GLBBUFFER;
}

class GLTFTools {

    public static var textureMapping:Map<BitmapTexture, ImageFile> = new Map<BitmapTexture, ImageFile>();
    
    var GENERATOR = "GLTFTools by Geepers Interactive Ltd. V1.0.0 - Greg Caldwell";
    var VERSION = "2.0";

    var embedData:BinaryData = null;
    var accessorIndex:Int = 0;
    var bufferIndex:Int = 0;
    var bufferViewIndex:Int = 0;
    var materialIndex:Int = 0;
    var imageIndex:Int = 0;
    var textureIndex:Int = 0;
    var nodeIndex:Int = 0;
    var meshIndex:Int = 0;

    var containerCtr:Int = 0;
    var imageCtr:Int = 0;
    var texturesUsed:Bool = false;

    var nodeMap:ObjectMap<Dynamic, Node> = new ObjectMap<Dynamic, Node>();
    var nodeChildrenMap:ObjectMap<Dynamic, Array<Node>> = new ObjectMap<Dynamic, Array<Node>>();
    var imageMap:Map<String, ImageFile> = new Map<String, ImageFile>();

    var gltf:Gltf;
    var extensionsUsed:Array<String>;
    var extensionsRequired:Array<String>;
    var accessors:Array<Accessor>;
    var animations:Array<Animation>;
    var bufferViews:Array<BufferView>;
    var cameras:Array<Camera>;
    var images:Array<Image>;
    var materials:Array<Material>;
    var meshes:Array<GLTFMesh>;
    var nodes:Array<Node>;
    var samplers:Array<Sampler>;
    var scenes:Array<Scene>;
    var skins:Array<Skin>;
    var textures:Array<Texture>;

    var mainBuffer:Buffer;
    var sceneNodes:Array<GltfId>;
    var scene:Scene;

    var bufferBytes:BytesBuffer;
    var bufferLength:Int = 0;
    var byteOffset:Int = 0;

    static var instance(get, null):GLTFTools;
    static function get_instance():GLTFTools {
        if (instance==null) instance = new GLTFTools();
        return instance;
    }

    function new() {}

    #if away3d
    public static function exportGLTFFromAway3D(container:ObjectContainer3D, embedData:Bool = true):String {
        return GLTFTools.instance.gltfFromAway3D(container, embedData ? BinaryData.EMBEDDED : BinaryData.EXTERNAL);
    }

    public static function exportGLBFromAway3D(container:ObjectContainer3D):Bytes {
        return GLTFTools.instance.glbFromAway3D(container);
    }

    function gltfFromAway3D(container:ObjectContainer3D, embedData:BinaryData):String {
        buildGLTFExport( container, embedData);

        return haxe.Json.stringify( gltf, "  " );
    }

    function glbFromAway3D(container:ObjectContainer3D):Bytes {
        buildGLTFExport( container, BinaryData.GLBBUFFER );

        var gltfBytes = Bytes.ofString( haxe.Json.stringify( gltf, "  " ) );
        var padCount = (gltfBytes.length % 4);
        if (padCount != 0) padCount = 4 - padCount;
        var gltfChunk:BytesBuffer = new BytesBuffer();
        gltfChunk.addInt32( gltfBytes.length + padCount );     // GLTF chunk length
        gltfChunk.addInt32( 0x4E4F534A );         // GLTF ascii
        gltfChunk.addBytes( gltfBytes, 0, gltfBytes.length );
        for (i in 0...padCount) gltfChunk.addByte(0x20);

        var binChunk:BytesBuffer = new BytesBuffer();
        padCount = bufferBytes.length % 4;
        if (padCount != 0) padCount = 4 - padCount;
        binChunk.addInt32( bufferBytes.length + padCount );   // Binary data chunck length
        binChunk.addInt32( 0x004E4942 );         // BIN ascii
        binChunk.addBytes( bufferBytes.getBytes(), 0, bufferBytes.length );
        for (i in 0...padCount) gltfChunk.addByte(0x0);
        
        var output:BytesBuffer = new BytesBuffer();
        output.addInt32( 0x46546C67 );    // Magic
        output.addInt32( 2 );               // Version
        output.addInt32( gltfChunk.length + binChunk.length + 12 );               // Total byte length
        output.addBytes( gltfChunk.getBytes(), 0, gltfChunk.length );
        output.addBytes( binChunk.getBytes(), 0, binChunk.length );

        return output.getBytes();
    }

    function buildGLTFExport(container:ObjectContainer3D, embedData:BinaryData) {
        accessorIndex = 0;
        bufferIndex = 0;
        bufferViewIndex = 0;
        materialIndex = 0;
        imageIndex = 0;
        textureIndex = 0;
        nodeIndex = 0;
        meshIndex = 0;
        containerCtr = 0;
        texturesUsed = false;

        nodeMap = new ObjectMap<Dynamic, Node>();
        nodeChildrenMap = new ObjectMap<Dynamic, Array<Node>>();
        imageMap = new Map<String, ImageFile>();
    
        extensionsUsed = null;
        extensionsRequired = null;
        accessors = null;
        animations = null;
        bufferViews = null;
        cameras = null;
        images = null;
        materials = null;
        meshes = null;
        nodes = null;
        samplers = null;
        scenes = null;
        skins = null;
        textures = null;
    
        mainBuffer = null;
        sceneNodes = null;
        scene = null;
    
        bufferBytes = null;
        bufferLength = 0;
        byteOffset = 0;

        this.embedData = embedData;
        nodeIndex = 0;
        bufferBytes = new BytesBuffer();

        processNode( container, null );
        allocateChildNodes( container );

        scene = { nodes: sceneNodes };

        createBuffer( "GLTF_" + Std.random(0xffffff) + "-data.bin", bufferBytes );

        if (texturesUsed) {
            var sampler:Sampler = { 
                magFilter: Linear,
                minFilter: LinearMipmapLinear
            }
            samplers = [];
            samplers.push( sampler );
        }

        gltf = {
            asset: {
                generator: GENERATOR,
                version: VERSION
            },
            scene: 0,
            scenes: [ scene ],
        }

        if (extensionsUsed!=null) gltf.extensionsUsed = extensionsUsed;
        if (extensionsRequired!=null) gltf.extensionsRequired = extensionsRequired;
        if (meshes!=null) gltf.meshes = meshes;
        if (accessors!=null) gltf.accessors = accessors;
        if (animations!=null) gltf.animations = animations;
        if (mainBuffer!=null) gltf.buffers = [ mainBuffer ];
        if (bufferViews!=null) gltf.bufferViews = bufferViews;
        if (cameras!=null) gltf.cameras = cameras;
        if (images!=null) gltf.images = images;
        if (materials!=null) gltf.materials = materials;
        if (meshes!=null) gltf.meshes = meshes;
        if (nodes!=null) gltf.nodes = nodes;
        if (samplers!=null) gltf.samplers = samplers;
        if (skins!=null) gltf.skins = skins;
        if (textures!=null) gltf.textures = textures;
    }

    function processNode(container:ObjectContainer3D, par:Dynamic) {
        var type = container.assetType;
        switch (type) {
            case Asset3DType.CONTAINER: processObjectContainer( container, par );
            case Asset3DType.MESH: processMesh( cast container, par );
        }

        var childNodeIds:Array<Int>;
        for (childIndex in 0...container.numChildren) {
            processNode( container.getChildAt(childIndex), container );
        }
    }

    function allocateChildNodes(container:ObjectContainer3D) {
        if (container.numChildren>0) {
            var childNodeList:Array<Int> = [];
            var node = nodeMap.get( container );
            if (nodeChildrenMap.exists( container )) {
                var childNodes = nodeChildrenMap.get( container );
                for (child in childNodes) {
                    var childNodeIndex = nodes.indexOf( child );
                    childNodeList.push( childNodeIndex );
                }
                node.children = childNodeList;

                for (childIndex in 0...container.numChildren) {
                    allocateChildNodes( container.getChildAt(childIndex) );
                }
            }
        }
    }

    function processObjectContainer(container:ObjectContainer3D, par:Dynamic ) {
        var name = (container.name==null || container.name == "" || container.name == "null") ? "Container_"+containerCtr : container.name;
        #if debug_export
        trace("Container: name="+name+" numChildren="+container.numChildren+" transform="+container.transform);
        #end
        addNode( container, par, name, container.transform );
        containerCtr++;
    }

    function processMesh(mesh:Mesh, par:Dynamic ) {
        #if debug_export
        trace("Mesh: name="+mesh.name+" numChildren="+mesh.numChildren+" transform="+mesh.transform);
        #end
        getMeshNodes( mesh, par );
  }

    function bytesFromFloats(floats:Vector<Float>):Bytes {
        var byteBuffer = new BytesBuffer();
        for (f in floats) byteBuffer.addFloat(f);
        return byteBuffer.getBytes();
    }

    function bytesFromInts(ints:Vector<Int>):Bytes {
        var byteBuffer = new BytesBuffer();
        for (i in ints) byteBuffer.addInt32(i);
        return byteBuffer.getBytes();
    }

    function getMeshNodes(baseMesh:Mesh, par:Dynamic) {
        var subMeshes = baseMesh.subMeshes;
        if (subMeshes!=null) {
            var ctr = 0;
            
            if (meshes==null) meshes = [];

            for (subMesh in subMeshes) {
                var name = baseMesh.name+"_"+ctr;
                #if debug_export
                trace("Processing subMesh: name="+name+" numVerts="+subMesh.numVertices);
                #end

                var csg:CompactSubGeometry = cast subMesh.subGeometry;
                var vertexPositions = csg.stripBuffer(0, 3);    //vertexPositionData;
                var vertexNormals = csg.stripBuffer(3, 3);      //vertexNormalData;
                fixNormals(vertexNormals);
                var indexes = subMesh.indexData.copy();         //Indices
                var count = subMesh.numVertices;
                
                var positionBufferViewIdx = addBufferView( name+"-positionBufferView", bytesFromFloats(vertexPositions), 12 );
                var normalBufferViewIdx = addBufferView( name+"-normalBufferView", bytesFromFloats(vertexNormals), 12 );
                var indicesBufferViewIdx = addBufferView( name+"-indicesBufferView", bytesFromInts(indexes), 2 );
                var positionAccIdx = addAccessor( name+"-position", positionBufferViewIdx, CTFloat, count, Vec3, getMinMax(vertexPositions, 3), 0 );
                var normalAccIdx = addAccessor( name+"-normal", normalBufferViewIdx, CTFloat, count, Vec3, getMinMax(vertexNormals, 3), 0 );
                var indexIdx = addAccessor( name+"-index", indicesBufferViewIdx, CTUnsignedInt, indexes.length, Scalar, null, 0 );

                var primitives:Array<MeshPrimitive> = [];
                var attr:Dynamic = { 
                    POSITION: positionAccIdx,
                    NORMAL: normalAccIdx
                };

                if (Std.isOfType(subMesh.material, TextureMaterial)) {
                    var uvs1 = csg.stripBuffer(9, 2);//UVData;
                    var uvBufferViewIdx = addBufferView( name+"-uvBufferView", bytesFromFloats(uvs1), 8 );
                    var uvs1AccIdx = addAccessor( name+"-uvs1", uvBufferViewIdx, CTFloat, count, Vec2, null, 0 );
                    attr.TEXCOORD_0 = uvs1AccIdx++;
                }

                var materialIdx = addMaterial( subMesh, name );

                var meshPrim:MeshPrimitive = {
                    attributes: attr,
                    indices: indexIdx,
                    material: materialIdx
                };

                primitives.push( meshPrim );
                
                var mesh:GLTFMesh = { 
                    primitives: primitives
                };
                meshes.push( mesh );

                addNode(subMesh, par, baseMesh.name+"_submesh_"+(ctr+1), baseMesh.transform, true);

                ctr++;
            }
        }
    }

    function fixNormals(normals:Vector<Float>) {
        var nCtr = 0;
        var norm:Vector3D = new Vector3D();
        while (nCtr < normals.length) {
            norm.x = normals[nCtr];
            norm.y = normals[nCtr+1];
            norm.z = normals[nCtr+2];
            norm.normalize();
            normals[nCtr] = Std.int(norm.x * 1000000) / 1000000;
            normals[nCtr+1] = Std.int(norm.y * 1000000) / 1000000;
            normals[nCtr+2] = Std.int(norm.z * 1000000) / 1000000;        
            nCtr+=3;
        }
    }

    function addNode(currentItem:Dynamic, parentItem:Dynamic, name:String, transform:Matrix3D, isMesh:Bool = false ) {
        var matData = transform.clone();
        // Scene flip if on scene root
        if (parentItem==null)
            matData.prependScale(-1, 1, 1);
        
        var m = matData.rawData;
        var node:Node = {
            name: name,
            matrix: [ m[0], m[1], m[2], m[3], m[4], m[5], m[6], m[7], m[8], m[9], m[10], m[11], m[12], m[13], m[14], m[15] ]
        };
        
        if (nodes==null) nodes = [];
        if (isMesh) {
            node.mesh = meshIndex;
            meshIndex++;
        }
        
        nodeMap.set( currentItem, node );
        nodes.push( node );
        
        if (parentItem==null) {
            if (sceneNodes==null) sceneNodes = [];
            sceneNodes.push( nodeIndex );
        } else {
            if (!nodeChildrenMap.exists(parentItem)) nodeChildrenMap.set(parentItem, []);
            var nodeList = nodeChildrenMap.get( parentItem );
            nodeList.push( node );
        }

        nodeIndex++;
    }

    function addBufferView(name:String, bytes:Bytes, stride:Int/*, target */):Int {
        
        var bytesLen = bytes.length;
        bufferBytes.addBytes( bytes, 0, bytesLen );

        // Ensure buffer ends on a 4 byte boundary
        var padlength = 4 - (bytesLen % 4);
        if (padlength % 4 != 4) {
            for (p in 0...padlength)
                bufferBytes.addByte(0);
        }
        bytesLen += padlength;

        var buffView:BufferView = {
            buffer: 0,
            byteLength: bytesLen,
            byteOffset: byteOffset,
            name: name
        }

        if (bufferViews==null) bufferViews = [];
        bufferViews.push( buffView );

        bufferLength += bytesLen;
        byteOffset += bytesLen;
        
        #if debug_export
        trace("BufferView: "+bufferViewIndex+" len="+buffView.byteLength+" off="+buffView.byteOffset+" name="+buffView.name+" stride="+buffView.byteStride+" padlength="+padlength);
        #end
        
        return bufferViewIndex++;
    }

    function createBuffer(uri:String, bytes:BytesBuffer) {
        var len = bytes.length;
        if (embedData==BinaryData.EMBEDDED) {
            var encoded = Base64.encode( bytes.getBytes() );
            uri = "data:application/gltf-buffer;base64,"+encoded;
        }
        mainBuffer = {
            byteLength: len
        }
        if (embedData!=BinaryData.GLBBUFFER)
            mainBuffer.uri = uri;
    }

    function getComponentByteCount(compType:ComponentType):Int {
        return switch (compType) {
            case CTShort, CTUnsignedShort: 2;
            case CTUnsignedInt, CTFloat :  4;
            default: 1;
        }       
    }
    function addAccessor(name:String, buffView:Int, compType:ComponentType, count:Int, type:AccessorType, minMax:MinMax = null, byteOffset:Int = 0):Int {

        var mult:Int = getComponentByteCount(compType);

        var acc:Accessor = {
            name: name,
            bufferView: buffView,
            componentType: compType,
            count: count,
            type: type,
            byteOffset: byteOffset * mult
        }
        if (minMax!=null) {
            acc.min = minMax.min;
            acc.max = minMax.max;
        }

        if (accessors==null) accessors=[];
        accessors.push( acc );

        #if debug_export
        trace("Accessor: "+accessorIndex+" name="+acc.name+" bv="+acc.bufferView+" ct="+acc.componentType+" count="+acc.count+" type="+acc.type+" min="+acc.min+" max="+acc.max+" byteOffset="+acc.byteOffset);
        #end 
        
        return accessorIndex++;
    }

    function getMinMax(data:Vector<Float>, stride:Int):MinMax {
        var mm:MinMax = { min:[], max:[] };
        for (element in 0...stride) {
            mm.min.push( Math.POSITIVE_INFINITY );
            mm.max.push( Math.NEGATIVE_INFINITY );
        }
        var ctr = 0;
        while (ctr<data.length) {
            for (element in 0...stride) {
                if (data[ctr+element] < mm.min[element]) mm.min[element] = data[ctr+element];
                if (data[ctr+element] > mm.max[element]) mm.max[element] = data[ctr+element];
            }
            ctr += stride;
        }
        return mm;
    }

    function addMaterial(subMesh:SubMesh, baseName:String):Int {
        var m = subMesh.material;
        var matMetalRough:MaterialMetalicRoughness = {
            metallicFactor: 0,
            roughnessFactor: 0.16801775892977194,
        }

        var normalInfo:MaterialNormalTextureInfo = null;

        if (Std.isOfType(m, TextureMaterial)) {
            texturesUsed = true;
            
            var texMat:TextureMaterial = cast m;
            var name = texMat.texture.name == null || texMat.texture.name=="" || texMat.texture.name=="null" ? baseName+"_image_"+imageCtr : texMat.name;
            var textureIndex = addTexture(name, cast texMat.texture);
            var textureInfo:TextureInfo = {
                index: textureIndex,
                texCoord: 0
            }

            matMetalRough.baseColorFactor = [
                0.30603279993281185,
                0.30603279993281185,
                0.30603279993281185,
                texMat.alpha
            ];
 
            matMetalRough.baseColorTexture = textureInfo;

            imageCtr++;

            if (texMat.normalMap!=null) {
                var name = texMat.normalMap.name == null || texMat.normalMap.name=="" || texMat.normalMap.name=="null" ? baseName+"_normal_"+imageCtr : texMat.name;
                var normalIndex = addTexture(name, cast texMat.normalMap);
                normalInfo = {
                    index: normalIndex,
                    texCoord: 0
                }

                imageCtr++;
            }
        } else if (Std.isOfType(m, ColorMaterial)) {
            var colMat:ColorMaterial = cast m;

            matMetalRough.baseColorFactor = [
                ((colMat.color >> 16) & 0xff) / 255.0,
                ((colMat.color >> 8) & 0xff) / 255.0,
                (colMat.color & 0xff) / 255.0,
                colMat.alpha
            ];
        }

        var mat:Material = {
            name: m.name,
            pbrMetallicRoughness: matMetalRough
        };

        if (normalInfo!=null) mat.normalTexture = normalInfo;

        if (materials==null) materials = [];
        materials.push( mat );

        return materialIndex++;
    }

    function addTexture(name:String, bitmapTex:BitmapTexture):Int {
        var imageInfo = addImage(name, bitmapTex);

        var texture = {
            source: imageInfo.index,
            name: "file:"+imageInfo.filename,
            "sampler": 0
        }
   
        if (textures==null) textures = [];
        textures.push( texture );
        return textureIndex++;
    }

    function addImage(name:String, bitmapTex:BitmapTexture):ImageFile {
        var filename:String;
        var bytes:BytesBuffer;
        var mimeType:String = "image/png";
        if (textureMapping.exists(bitmapTex)) {
            var image:ImageFile = textureMapping.get(bitmapTex);
            filename = image.filename;
            bytes = new BytesBuffer();
            bytes = image.data;
            var ext = "";
			var extIndex = filename.lastIndexOf(".");
            if (extIndex > -1) ext = filename.substring(extIndex + 1);
            mimeType = switch (ext) {
				case "jpg", "jpeg": "image/jpeg";
				case "png": "image/png";
				case "gif": "image/gif";
                case _: "";
            }
       } else {
            filename = name +".png";
            var bitmapData:BitmapData = cast(bitmapTex, BitmapTexture).bitmapData;
            var encodedBytes = bitmapData.image.encode(lime.graphics.ImageFileFormat.PNG);
            bytes = new BytesBuffer();
            bytes.addBytes(encodedBytes, 0, encodedBytes.length );
        }
        
        if (imageMap.exists(filename)) {
            return imageMap[filename];
        }

        var image:Image = {};
        switch (embedData) {
            case BinaryData.EMBEDDED:
                var encoded = Base64.encode( bytes.getBytes() );
                image.uri = "data:"+mimeType+";base64,"+encoded;
            case BinaryData.EXTERNAL:
                image.uri = filename;
            case BinaryData.GLBBUFFER:
                var imageBVId = addBufferView(filename, bytes.getBytes(), 0);
                image.bufferView = imageBVId;
                image.mimeType = ImagePng;
        }

        if (images==null) images = [];
        images.push( image );
        imageMap.set(filename, { filename: filename, data: null, index: imageIndex++ });

        return imageMap[filename];
    }

    #end
}