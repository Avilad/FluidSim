//
//  Shader.fsh
//  FluidSim
//
//  Created by SlEePlEs5 on 1/31/14.
//  Copyright (c) 2014 SlEePlEs5. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
