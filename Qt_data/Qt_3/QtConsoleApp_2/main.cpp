//#include <QCoreApplication>
#include <QDebug>
#include <QDateTime>
#include <QApplication>
#include "mainwindow.h"

int main(int argc, char *argv[])
{
    QApplication a(argc, argv); //QCoreApplication a(argc, argv);
    qDebug() << QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss.zzz");

    MainWindow w;
    w.show();

    return a.exec();
}
