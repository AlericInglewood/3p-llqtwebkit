/* Copyright (c) 2006-2010, Linden Research, Inc.
 *
 * LLQtWebKit Source Code
 * The source code in this file ("Source Code") is provided by Linden Lab
 * to you under the terms of the GNU General Public License, version 2.0
 * ("GPL"), unless you have obtained a separate licensing agreement
 * ("Other License"), formally executed by you and Linden Lab.  Terms of
 * the GPL can be found in GPL-license.txt in this distribution, or online at
 * http://secondlifegrid.net/technology-programs/license-virtual-world/viewerlicensing/gplv2
 *
 * There are special exceptions to the terms and conditions of the GPL as
 * it is applied to this Source Code. View the full text of the exception
 * in the file FLOSS-exception.txt in this software distribution, or
 * online at
 * http://secondlifegrid.net/technology-programs/license-virtual-world/viewerlicensing/flossexception
 *
 * By copying, modifying or distributing this software, you acknowledge
 * that you have read and understood your obligations described above,
 * and agree to abide by those obligations.
 *
 * ALL LINDEN LAB SOURCE CODE IS PROVIDED "AS IS." LINDEN LAB MAKES NO
 * WARRANTIES, EXPRESS, IMPLIED OR OTHERWISE, REGARDING ITS ACCURACY,
 * COMPLETENESS OR PERFORMANCE.
 */
#define FREEGLUT_STATIC

#include "zpr.h"
#include "llqtwebkit.h"

#include <iostream>
#include <string>
#include <direct.h>
#include <time.h>

bool gDebugMode = false;
int gBrowserWindowId=-1;
GLuint gBrowserTexture=-1;
GLuint gCheckerTexture=-1;

void idle(void)
{
	LLQtWebKit::getInstance()->pump(100);
	LLQtWebKit::getInstance()->grabBrowserWindow( gBrowserWindowId );
	glutPostRedisplay();
}

void display(void)
{
	glClear(GL_COLOR_BUFFER_BIT);

	glPushMatrix();

	glBindTexture(GL_TEXTURE_2D, gBrowserTexture);
	if(!gDebugMode)
	{
		const unsigned char* pixels=LLQtWebKit::getInstance()->getBrowserWindowPixels(gBrowserWindowId);
		if(pixels)
		{
			glTexSubImage2D(GL_TEXTURE_2D, 0,
								0, 0,
								LLQtWebKit::getInstance()->getBrowserWidth(gBrowserWindowId), LLQtWebKit::getInstance()->getBrowserHeight(gBrowserWindowId),
								GL_RGBA,
								GL_UNSIGNED_BYTE,
								pixels);
		};
	};
	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
	glBegin(GL_QUADS);
		glNormal3f( 0.0f, 0.0f, 1.0f);
		glTexCoord2f(0.0f, 0.0f); glVertex3f(-0.8f, -0.8f,  0.8f);
		glTexCoord2f(1.0f, 0.0f); glVertex3f( 0.8f, -0.8f,  0.8f);
		glTexCoord2f(1.0f, 1.0f); glVertex3f( 0.8f,  0.8f,  0.8f);
		glTexCoord2f(0.0f, 1.0f); glVertex3f(-0.8f,  0.8f,  0.8f);
	glEnd();

	glBindTexture(GL_TEXTURE_2D, gCheckerTexture);
	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
	glBegin(GL_QUADS);
		glNormal3f( 0.0f, 0.0f,1.0f);
		glTexCoord2f(1.0f, 0.0f); glVertex3f(-0.8f, -0.8f, -0.8f);
		glTexCoord2f(1.0f, 1.0f); glVertex3f(-0.8f,  0.8f, -0.8f);
		glTexCoord2f(0.0f, 1.0f); glVertex3f( 0.8f,  0.8f, -0.8f);
		glTexCoord2f(0.0f, 0.0f); glVertex3f( 0.8f, -0.8f, -0.8f);
	glEnd();



	glPopMatrix();

	glutSwapBuffers();
}

GLuint make_rgba_texture(int texture_width, int texture_height)
{
	const int texture_depth=4;

	unsigned char* texture_pixels = new unsigned char[texture_width*texture_height*texture_depth];

	const int num_squares=rand()%10+4;
	int sqr1_r=rand()%0xa0+0x20;
	int sqr1_g=rand()%0xa0+0x20;
	int sqr1_b=rand()%0xa0+0x20;
	int sqr1_alpha=0xff;

	int sqr2_r=rand()%0xa0+0x20;
	int sqr2_g=rand()%0xa0+0x20;
	int sqr2_b=rand()%0xa0+0x20;
	int sqr2_alpha=0x00;

	for(int y1=0;y1<num_squares;++y1)
	{
		for(int x1=0;x1<num_squares;++x1)
		{
			int px_start=texture_width*x1/num_squares;
			int px_end=(texture_width*(x1+1))/num_squares;
			int py_start=texture_height*y1/num_squares;
			int py_end=(texture_height*(y1+1))/num_squares;

			for(int y2=py_start;y2<py_end;++y2)
			{
				for(int x2=px_start;x2<px_end;++x2)
				{
					int rowspan=texture_width*texture_depth;

					if((y1%2)^(x1%2))
					{
						texture_pixels[y2*rowspan+x2*texture_depth+0]=sqr1_r;
						texture_pixels[y2*rowspan+x2*texture_depth+1]=sqr1_g;
						texture_pixels[y2*rowspan+x2*texture_depth+2]=sqr1_b;
						texture_pixels[y2*rowspan+x2*texture_depth+3]=sqr1_alpha;
					}
					else
					{
						texture_pixels[y2*rowspan+x2*texture_depth+0]=sqr2_r;
						texture_pixels[y2*rowspan+x2*texture_depth+1]=sqr2_g;
						texture_pixels[y2*rowspan+x2*texture_depth+2]=sqr2_b;
						texture_pixels[y2*rowspan+x2*texture_depth+3]=sqr2_alpha;
					};
				};
			};
		};
	};

	GLuint texture_id;
	glGenTextures(1, &texture_id);
	glBindTexture(GL_TEXTURE_2D, texture_id);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, texture_width, texture_height, 0, GL_RGBA, GL_UNSIGNED_BYTE, texture_pixels );

	delete [] texture_pixels;

	return texture_id;
}

int main(int argc, char* argv[])
{
	srand((unsigned int)time(0));

	const int browser_width=512;
	const int browser_height=512;

	glutInit(&argc, argv);
	glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGBA | GLUT_DEPTH);
	glutInitWindowPosition(80, 0);
	glutInitWindowSize(600,600);

	glutCreateWindow("3D Web Pages in OpenGL");

	glutDisplayFunc(display);
	glutIdleFunc(idle);

	zprInit();

	//glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
	//glClearDepth(1.0f);
	glEnable(GL_TEXTURE_2D);
	glDisable(GL_CULL_FACE);
	glDisable(GL_LIGHTING);
	//glDepthFunc(GL_LESS);
	//glDisable(GL_DEPTH_TEST);
	//glDepthMask(GL_FALSE);
	//glEnable(GL_NORMALIZE);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glEnable(GL_BLEND);


	gCheckerTexture = make_rgba_texture( browser_width, browser_height);

	if(gDebugMode)
	{
		gBrowserTexture = make_rgba_texture( browser_width, browser_height);
	}
	else
	{
		glGenTextures(1, &gBrowserTexture);
		glBindTexture(GL_TEXTURE_2D, gBrowserTexture);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, browser_width, browser_height, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0 );
	}

	std::string working_dir=_getcwd(NULL, 1024);
	std::string app_dir("");
	std::string profile_dir=working_dir+"/profile";
	std::string cookie_path=profile_dir+"/cookies.txt";
	LLQtWebKit::getInstance()->init(std::string(), app_dir, profile_dir, GetDesktopWindow());

	LLQtWebKit::getInstance()->enableJavaScript(true);
	LLQtWebKit::getInstance()->enableCookies(true);
	LLQtWebKit::getInstance()->enablePlugins(true);

	const std::string start_url("http://news.google.com");
	gBrowserWindowId=LLQtWebKit::getInstance()->createBrowserWindow(browser_width, browser_height);
	LLQtWebKit::getInstance()->setSize(gBrowserWindowId, browser_width, browser_height);
	LLQtWebKit::getInstance()->flipWindow(gBrowserWindowId, true);
	LLQtWebKit::getInstance()->navigateTo(gBrowserWindowId, start_url);

	glutMainLoop();

	return 0;
}
