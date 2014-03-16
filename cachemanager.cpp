#include "cachemanager.h"

#include <QDesktopServices>
#include <QUrl>
#include <QDir>
#include <QFile>
#include <QDateTime>
#include <QDebug>
#include <QSslConfiguration>
#include <QSslSocket>


CacheManager::CacheManager()
{
    m_manager = new QNetworkAccessManager(this);
    _cacheDir = QDesktopServices::storageLocation(QDesktopServices::CacheLocation) + "/bikemee/";
}

QString CacheManager::cartoJson() const
{
    //qDebug() << "Getting carto...";
    return _cartoJson;
}

void CacheManager::getContracts(bool forceRefresh)
{
    QFile file(_cacheDir + "contracts.json");
    if (!forceRefresh && file.exists())
    {
        qDebug() << "Contracts already in cache, not downloading";
        file.open(QIODevice::ReadOnly);
        QString contracts = QString::fromUtf8(file.readAll());
        file.close();
        emit contractsUpdated(contracts);
    }
    else if (forceRefresh)
    {
        QNetworkRequest req(QUrl("https://developer.jcdecaux.com/rest/vls/contracts"));
        QSslConfiguration config = req.sslConfiguration();
        config.setPeerVerifyMode(QSslSocket::VerifyNone);
        req.setSslConfiguration(config);
        QNetworkReply *reply = m_manager->get(req);
        connect(reply, SIGNAL(finished()), this, SLOT(getContractsFinished()));
    }
}

void CacheManager::getStationDetails(QString stationNumber)
{
    //qDebug() << "Getting station details...";
    QNetworkRequest req(QUrl("https://api.jcdecaux.com/vls/v1/stations/" + stationNumber +
                             "?contract=" + _currentCity + "&apiKey=xxx"));
    QSslConfiguration config = req.sslConfiguration();
    config.setPeerVerifyMode(QSslSocket::VerifyNone);
    req.setSslConfiguration(config);
    QNetworkReply *reply = m_manager->get(req);
    connect(reply, SIGNAL(finished()), this, SLOT(stationDetailsFinished()));
}

void CacheManager::downloadCarto(QString city)
{
    _currentCity = city;
    QFile file(_cacheDir + _currentCity + ".json");

    if (file.exists())
    {
        QFileInfo fileInfo(_cacheDir + _currentCity + ".json");
        qint64 fileAge = fileInfo.created().toMSecsSinceEpoch();
        qint64 now = QDateTime::currentMSecsSinceEpoch();
        qint64 dayInMillis = 1000 * 60 * 60 * 24;

        if (((now - fileAge) / dayInMillis) > 14) // If file is older than 2 weeks, refresh it.
        {
            qDebug() << "Removing current cached " + _currentCity + ".json";
            file.remove();
        }
    }
    if (file.exists())
    {
        qDebug() << "File exists, not downloading";
        file.open(QIODevice::ReadOnly);
        _cartoJson = QString::fromUtf8(file.readAll());
        file.close();
        emit cartoChanged();
    }
    else
    {
        qDebug() << "Downloading carto to: " + _cacheDir;
        //QNetworkRequest req(QUrl("https://api.jcdecaux.com/vls/v1/stations?contract=paris&apiKey=xxx"));
        QNetworkRequest req(QUrl("https://developer.jcdecaux.com/rest/vls/stations/" + _currentCity + ".json"));
        QSslConfiguration config = req.sslConfiguration();
        config.setPeerVerifyMode(QSslSocket::VerifyNone);
        req.setSslConfiguration(config);
        QNetworkReply *reply = m_manager->get(req);
        connect(reply, SIGNAL(finished()), this, SLOT(replyFinished()));
    }
}

void CacheManager::replyFinished()
{
    QNetworkReply *pReply = qobject_cast<QNetworkReply *>(sender());
    if (pReply->error() != QNetworkReply::NoError)
    {
        qDebug() << "Error while downloading carto:";
        qDebug() << pReply->errorString();
        pReply->deleteLater();
        return;
    }

    QByteArray data = pReply->readAll();
    _cartoJson = QString::fromUtf8(data);

    QDir cacheDir(_cacheDir);
    if (!cacheDir.exists())
    {
        cacheDir.mkpath(_cacheDir);
    }
    QFile file(_cacheDir + _currentCity + ".json");
    file.open(QIODevice::WriteOnly);
    file.write(data);
    file.close();
    emit cartoChanged();
    pReply->deleteLater();
}

void CacheManager::stationDetailsFinished()
{
    QNetworkReply *pReply = qobject_cast<QNetworkReply *>(sender());
    if (pReply->error() != QNetworkReply::NoError)
    {
        qDebug() << "Error while getting stations details:";
        qDebug() << pReply->errorString();
        pReply->deleteLater();
        return;
    }

    QByteArray data = pReply->readAll();
    QString stationDetails = QString::fromUtf8(data);
    emit gotStationDetails(stationDetails);
    pReply->deleteLater();
}

void CacheManager::getContractsFinished()
{
    QNetworkReply *pReply = qobject_cast<QNetworkReply *>(sender());
    if (pReply->error() != QNetworkReply::NoError)
    {
        qDebug() << "Error while getting stations details:";
        qDebug() << pReply->errorString();
        pReply->deleteLater();
        return;
    }

    QByteArray data = pReply->readAll();
    QString contracts = QString::fromUtf8(data);
    QDir cacheDir(_cacheDir);
    if (!cacheDir.exists())
    {
        cacheDir.mkpath(_cacheDir);
    }
    QFile file(_cacheDir + "contracts.json");
    file.open(QIODevice::WriteOnly);
    file.write(data);
    file.close();

    emit contractsUpdated(contracts);
    pReply->deleteLater();
}

bool CacheManager::removeCacheDir()
{
    bool result = true;
    QDir dir(_cacheDir);

    if (dir.exists(_cacheDir)) {
        Q_FOREACH(QFileInfo info,
                  dir.entryInfoList(QDir::NoDotAndDotDot | QDir::System |
                                    QDir::Hidden  | QDir::AllDirs |
                                    QDir::Files, QDir::DirsFirst)) {
            result = QFile::remove(info.absoluteFilePath());

            if (!result) {
                return result;
            }
        }
        result = dir.rmdir(_cacheDir);
    }
    return result;
}
