camera   = undefined
c_camera = undefined
scene    = undefined
renderer = undefined
mesh     = undefined
material = undefined
sky      = undefined

controls = undefined
stats    = undefined

car          = undefined
carpaint_mat = undefined

sphere_mesh = undefined

L = 1800

WIDTH  = 960
HEIGHT = WIDTH/16*9

mime = 'video/webm'

class video_grabber 

    constructor: (@canvas)->
        @media_source = new MediaSource
        @media_source.addEventListener 'sourceopen', @handle_source_open, false        
        isSecureOrigin = location.protocol == 'https:' or location.hostname == 'localhost'
        
        if !isSecureOrigin
            alert 'getUserMedia() must be run from a secure origin: HTTPS or localhost.' + '\n\nChanging protocol to HTTPS'
            location.protocol = 'HTTPS'

        @stream = canvas.captureStream()
        # frames per second
        console.log 'Started @stream capture from canvas element: ', @stream

    handle_source_open: (event) =>
        console.log 'MediaSource opened'
        @sourceBuffer = @media_source.addSourceBuffer('video/webm; codecs="vp8"')
        console.log 'Source buffer: ', @sourceBuffer

    handle_data_available: (event) =>
        if event.data and event.data.size > 0
            @recorded_blobs?.push event.data

    handle_stop: (event) =>
        console.log 'Recorder stopped: ', event

    toggle_recording: =>
        if recordButton.textContent == 'Start Recording'
            startRecording()
        else
            stopRecording()
            recordButton.textContent = 'Start Recording'
            playButton.disabled = false
            downloadButton.disabled = false

    start_recording: =>
        options = mimeType: mime
        @recorded_blobs = []
        try
            @media_recorder = new MediaRecorder(@stream, options)
        catch e0
            console.log 'Unable to create MediaRecorder with options Object: ', e0
            try
                options = mimeType: "#{mime},codecs=vp9"
                @media_recorder = new MediaRecorder(@stream, options)
            catch e1
              console.log 'Unable to create MediaRecorder with options Object: ', e1
            try
                options = 'video/vp8'
                # Chrome 47
                @media_recorder = new MediaRecorder(@stream, options)
            catch e2
                alert 'MediaRecorder is not supported by this browser.\n\n' + 'Try Firefox 29 or later, or Chrome 47 or later, with Enable experimental Web Platform features enabled from chrome://flags.'
                console.error 'Exception while creating MediaRecorder:', e2

        console.log 'Created MediaRecorder', @media_recorder, 'with options', options
        @media_recorder.onstop          = @handle_stop
        @media_recorder.ondataavailable = @handle_data_available
        @media_recorder.start 100
        # collect 100ms of data
        console.log 'MediaRecorder started', @media_recorder

    stop_recording: =>
        @media_recorder.stop()
        # console.log 'Recorded Blobs: ', @recorded_blobs
        unless @video
            @video = document.createElement "video"
            document.body.appendChild @video
            @video.controls = true
            
        superBuffer = new Blob(@recorded_blobs, type: mime)
        @video.src = window.URL.createObjectURL superBuffer


    download: =>
        blob = new Blob(@recorded_blobs, type: mime)
        url = window.URL.createObjectURL(blob)
        a = document.createElement('a')
        a.style.display = 'none'
        a.href = url
        a.download = 'carpaint.webm'
        document.body.appendChild a
        a.click()
        setTimeout (->
            document.body.removeChild a
            window.URL.revokeObjectURL url
            return
        ), 100



shader_loader = (vertex_url, fragment_url, onLoad, onProgress, onError) ->
    vertex_loader = new (THREE.XHRLoader)(THREE.DefaultLoadingManager)
    vertex_loader.setResponseType 'text'
    vertex_loader.load vertex_url, ((vertex_text) ->
        fragment_loader = new (THREE.XHRLoader)(THREE.DefaultLoadingManager)
        fragment_loader.setResponseType 'text'
        fragment_loader.load fragment_url, (fragment_text) -> onLoad vertex_text, fragment_text
    ), onProgress, onError

rnd = (r)-> (Math.random()-Math.random())*r/2.0

environment = []
lights = []
create_evironment = ->
    textureLoader = new THREE.TextureLoader
    materials = (new THREE.MeshBasicMaterial({ color: 0xffffff, map: textureLoader.load("res/txt#{i}.jpg") }) for i in [1..4])

    white_mat = new THREE.MeshBasicMaterial color: 0xffffff, side: THREE.DoubleSide 
    for f in [0..10]

        switch f%3
            when 0 
                plane = new THREE.Mesh new THREE.PlaneGeometry( 800, 600, 1, 1 ), materials[f%4]
                plane.position.set rnd(L), 300, 200+rnd(100)
                plane.rotateX Math.PI
            when 1
                plane = new THREE.Mesh new THREE.PlaneGeometry( 800, 600, 1, 1 ), materials[f%4]
                plane.position.set rnd(L), 300,-200+rnd(100)
            when 2 
                plane = new THREE.Mesh new THREE.CircleGeometry(20+rnd(50), 16), white_mat
                plane.rotateX Math.PI / 2.0 
                plane.position.set rnd(L), 200+rnd(100), rnd(800)
        plane.visible =false
        scene.add plane
        environment.push plane

    # for f in [0..5]
    #     l = new THREE.DirectionalLight 0xffffff
    #     l.position.set(rnd(L), 200, rnd(400)).normalize()
    #     scene.add l
    #     lights.push l

init = ->

    renderer = new (THREE.WebGLRenderer)
    renderer.setPixelRatio window.devicePixelRatio
    renderer.setSize WIDTH, HEIGHT
    document.body.appendChild renderer.domElement

    scene = new THREE.Scene

    camera = new THREE.PerspectiveCamera(45, WIDTH / HEIGHT, 1, 100000)
    camera.position.z = 500
    
    c_camera = new THREE.CubeCamera  1, 1000, 256
    c_camera.rotateY Math.PI  
    
    c_camera.renderTarget.texture.minFilter = THREE.LinearMipMapLinearFilter
    scene.add c_camera

    # Skybox
    skyshader = THREE.ShaderLib['cube']
    skyshader.uniforms['tCube'].value = c_camera.renderTarget.texture
    skymaterial = new THREE.ShaderMaterial
        fragmentShader: skyshader.fragmentShader
        vertexShader  : skyshader.vertexShader
        uniforms      : skyshader.uniforms
        depthWrite    : false
        side          : THREE.BackSide

    sky = new (THREE.Mesh)(new (THREE.BoxGeometry)(400, 400, 400), skymaterial)
    sky.visible = false
    scene.add sky
    
    controls = new THREE.TrackballControls(camera, renderer.domElement)
    # controls.addEventListener 'change', render
    
    normalMap = THREE.ImageUtils.loadTexture('res/car_normal.png', null, (something) ->render() )

    uniforms = 
        paintColor1            : type: 'c', value: new (THREE.Color)(0x002f66)
        paintColor2            : type: 'c', value: new (THREE.Color)(0x002c99)
        paintColor3            : type: 'c', value: new (THREE.Color)(0x276296)
        normalMap              : type: 't', value: normalMap
        normalScale            : type: 'f', value: 0.0, min: 0.0, max: 1.0
        glossLevel             : type: 'f', value: 1.0, min: 0.0, max: 5.0
        brightnessFactor       : type: 'f', value: 1.0, min: 0.0, max: 1.0
        envMap                 : type: 't', value: c_camera.renderTarget.texture
        microflakeNMap         : type: 't', value: THREE.ImageUtils.loadTexture('res/SparkleNoiseMap.png')
        flakeColor             : type: 'c', value: new (THREE.Color)(0xFFFFFF)
        flakeScale             : type: 'f', value: -30.0 , min: -50.0 , max: 1.0
        normalPerturbation     : type: 'f', value: 1.0, min: -1.0, max: 1.0
        microflakePerturbationA: type: 'f', value: 0.1, min: -1.0, max: 1.0
        microflakePerturbation : type: 'f', value: 0.48, min: 0.0, max: 1.0

    uniforms.microflakeNMap.value.wrapS = uniforms.microflakeNMap.value.wrapT = THREE.RepeatWrapping
    shader_loader 'res/carpaint.vert', 'res/carpaint.frag', (vert, frag) ->
        carpaint_mat = new THREE.ShaderMaterial
            uniforms      : uniforms
            vertexShader  : vert
            fragmentShader: frag
            side          : THREE.DoubleSide
            derivatives   : true

        loader = new THREE.OBJLoader
        loader.load 'res/bmw.obj', (object) ->
            car = object.children[0]
            car.material = carpaint_mat
            scene.add car
            render()
    
    # light = new (THREE.AmbientLight)(0x404040)
    # soft white light
    # scene.add light

    cube_shader = THREE.ShaderLib[ "cube" ]
    cube_mat = new THREE.ShaderMaterial( {
        fragmentShader: cube_shader.fragmentShader,
        vertexShader  : cube_shader.vertexShader,
        uniforms      : cube_shader.uniforms,
        depthWrite    : false,
        side          : THREE.BackSide
    } )
    cube_mat.uniforms[ "tCube" ].value = c_camera.renderTarget.texture

    sphere_mat = new THREE.MeshBasicMaterial( { envMap: c_camera.renderTarget.texture } )
    sphere_mesh = new THREE.Mesh( new THREE.SphereBufferGeometry( 30.0, 48, 24 ), sphere_mat )
    sphere_mesh.position.z = -100
    scene.add sphere_mesh
    
    create_evironment()

    # stats
    stats = new Stats
    stats.domElement.style.position = 'absolute'
    stats.domElement.style.bottom   = '0px'
    
    document.body.appendChild stats.domElement
    setupControls uniforms
    window.addEventListener 'resize', onWindowResize, false

onWindowResize = ->
    camera.aspect = WIDTH / HEIGHT
    camera.updateProjectionMatrix()
    renderer.setSize WIDTH, HEIGHT
    controls.handleResize()
    render()

animate = ->
    for e in environment
        e.position.x += 10.0;
        if e.position.x > L/2.0
            e.position.x = -L/2.0
    
    # for l in lights
    #     l.position.x += 10.0;
    #     if l.position.x > L/2.0
    #         l.position.x = -L/2.0

    requestAnimationFrame animate
    controls.update()
    render()

render = ->

    car?.visible = false
    sphere_mesh?.visible = false
    e?.visible = true for e in environment
    c_camera.update renderer, scene
    # carpaint_mat.envMap = c_camera.renderTarget.texture
    
    car?.visible = true
    sphere_mesh?.visible = true
    e?.visible = false for e in environment
    renderer.render scene, camera
    stats?.update()

setupControls = (ob) ->

    gui = new dat.GUI
    
    disable_btn = (btn)->
        bs = btn.domElement.parentElement.style
        bs.pointerEvents = "none"
        bs.opacity       = .2;

    enable_btn = (btn)->
        bs = btn.domElement.parentElement.style
        bs.pointerEvents = null
        bs.opacity       = null 
    
    grabber = new video_grabber renderer.context.canvas    
    buttons = 
        record: ->
            disable_btn rec_btn
            enable_btn  stp_btn
            do grabber?.start_recording
        stop: ->
            disable_btn stp_btn
            enable_btn  rec_btn
            enable_btn  dwn_btn
            do grabber?.stop_recording
        download: ->
            do grabber.download

    rec_btn = gui.add buttons, "record"
    stp_btn = gui.add buttons, "stop"
    dwn_btn = gui.add buttons, "download"
    
    disable_btn stp_btn
    disable_btn dwn_btn

    sceneFolder = gui.addFolder('Scene')
    sceneFolder.add(sky, 'visible').name('Show Cubemap').onChange ->render()
    sceneFolder.open()
    
    uniformsFolder = gui.addFolder('Uniforms')
    for key of ob
        if ob[key].type == 'f'
            controller = uniformsFolder.add(ob[key], 'value').name(key)
            if typeof ob[key].min != 'undefined'
                controller = controller.min(ob[key].min).name(key)
            if typeof ob[key].max != 'undefined'
                controller = controller.max(ob[key].max).name(key)
            controller.onChange (value) ->
                @object.value = parseFloat(value)
                render()
        else if ob[key].type == 'c'
            ob[key].guivalue = [
                ob[key].value.r * 255
                ob[key].value.g * 255
                ob[key].value.b * 255
            ]
            controller = uniformsFolder.addColor(ob[key], 'guivalue').name(key)
            controller.onChange (value) ->
                @object.value.setRGB value[0] / 255, value[1] / 255, value[2] / 255
                render()

    uniformsFolder.open()

    sourceFolder = gui.addFolder('Source')
    butob = 
        'view vertex shader code': ->
            TINY.box.show
            html: '<div style="width: 500px; height: 500px;"><h3 style="margin: 0px; padding-bottom: 5px;">Vertex Shader</h3><pre style="overflow: scroll; height: 470px;">' + document.getElementById('vertexShader').text + '</pre></div>'
            animate: false
            close: false
            top: 5
        'view fragment shader code': ->
            TINY.box.show
            html: '<div style="width: 500px; height: 500px;"><h3 style="margin: 0px; padding-bottom: 5px;">Fragment Shader</h3><pre style="overflow: scroll; height: 470px;">' + document.getElementById('fragmentShader').text + '</pre></div>'
            animate: false
            close: false
            top: 5
    sourceFolder.add butob, 'view vertex shader code'
    sourceFolder.add butob, 'view fragment shader code'

init()
animate()

