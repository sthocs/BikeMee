#include <QtGui/QApplication>
#include <QDeclarativeContext>
#include <inneractiveplugin.h>
#include "qmlapplicationviewer.h"
#include "cachemanager.h"

Q_DECL_EXPORT int main(int argc, char *argv[])
{
    QScopedPointer<QApplication> app(createApplication(argc, argv));

    CacheManager cacheManager;

    QmlApplicationViewer viewer;

    inneractivePlugin::initializeEngine(viewer.engine());

    viewer.setOrientation(QmlApplicationViewer::ScreenOrientationAuto);
    viewer.rootContext()->setContextProperty("cacheManager", &cacheManager);
    viewer.setMainQmlFile(QLatin1String("qml/BikeMee/main.qml"));
    viewer.showExpanded();

    return app->exec();
}
